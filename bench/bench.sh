#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WHICH="${1:-both}"
LEVEL="${LEVEL:-4}"
ZLEVEL="${ZLEVEL:-default}"
FILE="${FILE:-wikipedia.html}"
DURATION="${DURATION:-10s}"
CONCURRENCY="${CONCURRENCY:-$(nproc)}"

ZSTD_PORT=9081
BR_PORT=9082

if ! command -v hey >/dev/null; then
	echo "hey not found in PATH (go install github.com/rakyll/hey@latest)" >&2
	exit 1
fi

CONFIG="$(mktemp)"
CADDY_PID=""
cleanup() {
	stop_caddy
	rm -f "$CONFIG"
}
trap cleanup EXIT

jq --argjson lvl "$LEVEL" --arg zlvl "$ZLEVEL" \
	'.apps.http.servers.br.routes[0].handle[0].encodings.br.level = $lvl
	 | .apps.http.servers.zstd.routes[0].handle[0].encodings.zstd.level = $zlvl' \
	"$ROOT/caddy.json" >"$CONFIG"

start_caddy() {
	local bin="$1"
	if [[ ! -x "$bin" ]]; then
		echo "missing binary $bin — run ./build.sh first" >&2
		exit 1
	fi
	"$bin" run --config "$CONFIG" >/tmp/caddy-bench.log 2>&1 &
	CADDY_PID=$!
	local port
	for port in "$ZSTD_PORT" "$BR_PORT"; do
		local ok=""
		for _ in {1..50}; do
			if curl -sf -o /dev/null "http://127.0.0.1:$port/$FILE"; then ok=1; break; fi
			sleep 0.1
		done
		if [[ -z "$ok" ]]; then
			echo "caddy did not come up on :$port — see /tmp/caddy-bench.log" >&2
			exit 1
		fi
	done
}

stop_caddy() {
	if [[ -n "${CADDY_PID:-}" ]] && kill -0 "$CADDY_PID" 2>/dev/null; then
		kill "$CADDY_PID" 2>/dev/null || true
		wait "$CADDY_PID" 2>/dev/null || true
	fi
	CADDY_PID=""
}

raw=$(stat -c%s "$ROOT/www/$FILE")

measure() {
	local port="$1" ae="$2"
	local url="http://127.0.0.1:$port/$FILE"
	local compressed rps
	compressed=$(curl -sf -H "Accept-Encoding: $ae" -o /dev/null \
		-w '%{size_download}' "$url")
	rps=$(hey -z "$DURATION" -c "$CONCURRENCY" \
		-H "Accept-Encoding: $ae" "$url" 2>/dev/null \
		| awk '/Requests\/sec:/ {printf "%.1f", $2}')
	echo "$compressed $rps"
}

row() { # <encoder label> <compressed> <rps>
	local ratio
	ratio=$(awk -v r="$raw" -v c="$2" 'BEGIN{printf "%.3f", c/r}')
	printf "%-9s %10d %10d %8s %12s\n" "$1" "$raw" "$2" "$ratio" "$3"
}

printf "\nfile: %s   br level: %s   zstd level: %s   concurrency: %s   duration: %s\n\n" \
	"$FILE" "$LEVEL" "$ZLEVEL" "$CONCURRENCY" "$DURATION"
printf "%-9s %10s %10s %8s %12s\n" \
	"encoder" "raw" "compressed" "ratio" "req/s"
printf "%-9s %10s %10s %8s %12s\n" \
	"-------" "---" "----------" "-----" "-----"

zstd_done=""
bench_variant() { # <label> <binary> <run-zstd?>
	local label="$1" bin="$2" want_zstd="$3"
	echo ">> $label: starting $(basename "$bin")" >&2
	start_caddy "$bin"
	if [[ -n "$want_zstd" && -z "$zstd_done" ]]; then
		echo ">> baseline: hey zstd (-c $CONCURRENCY -z $DURATION)" >&2
		read -r z_size z_rps < <(measure "$ZSTD_PORT" "zstd")
		row "zstd" "$z_size" "$z_rps"
		zstd_done=1
	fi
	echo ">> $label: hey br (-c $CONCURRENCY -z $DURATION)" >&2
	read -r b_size b_rps < <(measure "$BR_PORT" "br")
	row "$label" "$b_size" "$b_rps"
	stop_caddy
}

case "$WHICH" in
	this)   bench_variant "this"   "$ROOT/caddy-this"   1 ;;
	ueffel) bench_variant "ueffel" "$ROOT/caddy-ueffel" 1 ;;
	both)
		bench_variant "this"   "$ROOT/caddy-this"   1
		bench_variant "ueffel" "$ROOT/caddy-ueffel" "" ;;
	*) echo "usage: $0 [this|ueffel|both]" >&2; exit 1 ;;
esac

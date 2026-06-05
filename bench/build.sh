#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$(cd "$ROOT/.." && pwd)"
GOBIN="$(go env GOPATH)/bin"
XCADDY="$GOBIN/xcaddy"

if [[ ! -x "$XCADDY" ]]; then
	echo ">> installing xcaddy into $GOBIN"
	go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
fi

cd "$ROOT"

echo ">> building caddy-this (github.com/fuckoffel/caddy-brotli from $PLUGIN)"
"$XCADDY" build \
	--output "$ROOT/caddy-this" \
	--with "github.com/fuckoffel/caddy-brotli=$PLUGIN"

echo ">> building caddy-ueffel (github.com/ueffel/caddy-brotli)"
"$XCADDY" build \
	--output "$ROOT/caddy-ueffel" \
	--with "github.com/ueffel/caddy-brotli"

echo
echo ">> built caddy-this:   $(./caddy-this version)"
echo ">> built caddy-ueffel: $(./caddy-ueffel version)"

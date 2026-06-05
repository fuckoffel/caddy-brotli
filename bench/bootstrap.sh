#!/usr/bin/env bash

set -euo pipefail

GO_VERSION="${GO_VERSION:-1.26.4}"

SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then
	if command -v sudo >/dev/null; then
		SUDO="sudo"
	else
		echo "this script needs root or sudo to install system packages" >&2
		exit 1
	fi
fi

case "$(uname -m)" in
	x86_64)  GOARCH="amd64" ;;
	aarch64) GOARCH="arm64" ;;
	*) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if command -v dnf >/dev/null; then
	PKG="dnf"
elif command -v yum >/dev/null; then
	PKG="yum"
else
	echo "no dnf/yum found — is this an Amazon Linux instance?" >&2
	exit 1
fi

echo ">> installing system packages (git, jq, tar, gzip) via $PKG"
$SUDO "$PKG" install -y git jq tar gzip

# --- Go ---------------------------------------------------------------------
GO_ROOT="/usr/local/go"
want="go${GO_VERSION}"
have=""
if [[ -x "$GO_ROOT/bin/go" ]]; then
	have="$("$GO_ROOT/bin/go" version | awk '{print $3}')"
fi

if [[ "$have" == "$want" ]]; then
	echo ">> $want already installed at $GO_ROOT"
else
	tarball="${want}.linux-${GOARCH}.tar.gz"
	url="https://go.dev/dl/${tarball}"
	echo ">> installing $want for $GOARCH from $url"
	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/$tarball" "$url"
	$SUDO rm -rf "$GO_ROOT"
	$SUDO tar -C /usr/local -xzf "$tmp/$tarball"
	rm -rf "$tmp"
fi

export PATH="$GO_ROOT/bin:$PATH"
GOPATH_BIN="$($GO_ROOT/bin/go env GOPATH)/bin"
export PATH="$GOPATH_BIN:$PATH"

PROFILE="/etc/profile.d/go.sh"
echo ">> writing PATH to $PROFILE"
$SUDO tee "$PROFILE" >/dev/null <<EOF
export PATH="$GO_ROOT/bin:\$(go env GOPATH 2>/dev/null)/bin:\$PATH"
EOF

# --- hey (load generator used by bench.sh) ----------------------------------
if command -v hey >/dev/null; then
	echo ">> hey already on PATH"
else
	echo ">> installing hey (github.com/rakyll/hey)"
	go install github.com/rakyll/hey@latest
fi

echo
echo ">> done."
echo "   $(go version)"
echo "   hey:    $(command -v hey)"
echo "   open a new shell (or 'source $PROFILE') so PATH sticks, then run ./build.sh"

#!/usr/bin/env bash
# Install xwww (fork of awww with extra transitions): checksum-verified
# prebuilt release for this arch, with a source-build fallback.
# Requires: curl, tar and sudo; rust/cargo only for the fallback build.
# Installs only the two binaries davincix uses (client `xwww` and daemon
# `xwww-daemon`) in /usr/local/bin.
# Env: XWWW_VERSION overrides the release tag (default v0.12.1).
set -euo pipefail

VERSION="${XWWW_VERSION:-v0.12.1}"
case "$(uname -m)" in
    x86_64) ARCH="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) ARCH="aarch64-unknown-linux-gnu" ;;
    *) ARCH="" ;;
esac

install_release() {
    local base="xwww-${VERSION}-${ARCH}" url tmp
    url="https://github.com/x-ports/xwww/releases/download/${VERSION}/${base}.tar.gz"
    tmp="$(mktemp -d)"
    printf ':: downloading %s\n' "$base"
    curl -fsSL "$url" -o "$tmp/pkg.tar.gz"
    if curl -fsSL "$url.sha256" -o "$tmp/pkg.sha256" 2>/dev/null; then
        local exp act
        exp="$(cut -d' ' -f1 "$tmp/pkg.sha256" | head -1)"
        act="$(sha256sum "$tmp/pkg.tar.gz" | cut -d' ' -f1)"
        if [ -z "$exp" ] || [ "$exp" != "$act" ]; then
            printf 'xwww: checksum mismatch; aborting\n' >&2
            rm -rf "$tmp"
            return 1
        fi
    else
        printf 'xwww: checksum file unavailable; continuing without verification\n' >&2
    fi
    tar -xzf "$tmp/pkg.tar.gz" -C "$tmp"
    local d="$tmp/$base"
    if [ ! -f "$d/xwww" ] || [ ! -f "$d/xwww-daemon" ]; then
        printf 'xwww: unexpected tarball layout\n' >&2
        rm -rf "$tmp"
        return 1
    fi
    sudo install -Dm755 "$d/xwww" "$d/xwww-daemon" /usr/local/bin/
    rm -rf "$tmp"
}

install_source() {
    local src="${XDG_CACHE_HOME:-$HOME/.cache}/xwww-build"
    if [ -d "$src/.git" ]; then
        git -C "$src" pull --ff-only --quiet
    else
        rm -rf "$src"
        git clone --depth 1 https://github.com/x-ports/xwww "$src" --quiet
    fi
    if ! command -v cargo >/dev/null 2>&1; then
        printf 'xwww: cargo missing (install rust) and no prebuilt release available\n' >&2
        return 1
    fi
    (cd "$src" && cargo build --release)
    sudo install -Dm755 "$src/target/release/xwww" "$src/target/release/xwww-daemon" /usr/local/bin/
}

if [ -n "$ARCH" ] && install_release; then
    :
else
    printf 'xwww: prebuilt release unavailable/failed; building from source\n' >&2
    install_source
fi

printf 'installed: %s\n' "$(command -v xwww-daemon)"

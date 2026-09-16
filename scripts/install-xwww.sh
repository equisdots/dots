#!/usr/bin/env bash
# Install xwww (fork of awww with extra transitions): checksum-verified
# prebuilt release for this arch, with a source-build fallback.
# Requires: curl, tar and sudo; rust/cargo only for the fallback build.
# Binaries land in /usr/local/bin (client `xwww`, daemon `xwww-daemon`).
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
    if [ -d "$d/man" ]; then
        sudo install -Dm644 "$d"/man/*.1 /usr/local/share/man/man1/
    fi
    if [ -f "$d/completions/xwww.bash" ]; then
        sudo install -Dm644 "$d/completions/xwww.bash" /usr/local/share/bash-completion/completions/xwww
    fi
    if [ -f "$d/completions/_xwww" ]; then
        sudo install -Dm644 "$d/completions/_xwww" /usr/local/share/zsh/site-functions/_xwww
    fi
    if [ -f "$d/completions/xwww.fish" ]; then
        sudo install -Dm644 "$d/completions/xwww.fish" /usr/local/share/fish/vendor_completions.d/xwww.fish
    fi
    if [ -f "$d/contrib/xwww-daemon.service" ]; then
        sed 's|/usr/bin/xwww-daemon|/usr/local/bin/xwww-daemon|' "$d/contrib/xwww-daemon.service" \
            | sudo tee /etc/systemd/user/xwww-daemon.service >/dev/null
    fi
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

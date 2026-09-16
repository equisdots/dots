#!/usr/bin/env bash
# Build and install xwww (fork of awww: extra transitions) from source.
# Requires: rust/cargo, git and sudo. Installs to /usr/local/bin.
set -euo pipefail
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/xwww-build"
if [[ -d "$SRC/.git" ]]; then git -C "$SRC" pull --ff-only --quiet; else git clone --depth 1 https://github.com/x-ports/xwww "$SRC" --quiet; fi
cd "$SRC"
cargo build --release
sudo install -m755 target/release/xwww target/release/xwww-daemon /usr/local/bin/
printf 'installed: %s\n' "$(command -v xwww-daemon)"

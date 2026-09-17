# equisdots · dots

Meta installer and updater for the equisdots desktop stack. One command clones
every repo of the org, places each piece where it belongs and keeps them in
sync.

## Stack

| Repo | What it provides | Installed to |
|---|---|---|
| [hyprland](https://github.com/equisdots/hyprland) | Compositor config (Lua), scripts, installer | `~/.config/hypr` |
| [shell](https://github.com/equisdots/shell) | Quickshell UI (bar, panels, editor, popups) | `~/.config/hypr/scripts/quickshell` |
| [palettes](https://github.com/equisdots/palettes) | Color palettes (JSON set + schema) | `.../quickshell/dock/palettes` |
| [davincix](https://github.com/equisdots/davincix) | Wallpaper fetch/apply kernel | `~/.local/bin/davincix` |
| [theme-sync](https://github.com/equisdots/theme-sync) | Cross-app theme regeneration | `~/.local/bin/theme-sync` |
| [timex](https://github.com/equisdots/timex) | Time & weather engine (providers, calendar popup UI, settings tab) | engine `~/.local/share/equisdots/timex` + `~/.local/bin/timex`; UI → `.../quickshell/ui/timex` |
| [login](https://github.com/equisdots/login) | Static minimal SDDM greeter | `/usr/share/sddm/themes/x` (one-time, `dots system`) |

Repos are cloned under `~/.local/share/equisdots/<repo>`.

## Usage

```sh
git clone https://github.com/equisdots/dots.git
cd dots
./dots setup       # EVERYTHING: system stack (sudo) + user payload, one run
./dots system      # packages, fonts, login theme, PAM, external configs (sudo)
./dots install     # clone/update every repo and place it (also installs `dots`)
./dots doctor      # check dependencies, clones and installed paths
./dots list        # repo status (clean / dirty / missing)
./dots update      # pull everything and re-apply
./dots uninstall   # remove the created links and the updater timer
```

`dots install` also drops a `~/.local/bin/dots` wrapper, so after the first
run the `dots` command is available from anywhere.

`install` never deletes your live config: it copies over it and keeps your
`settings.json` untouched. For a full purge you must remove `~/.config/hypr`
yourself.

### Fresh machine

One command (recommended):

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/equisdots/dots/main/dots) setup -y
```

This runs the system stack (distro packages, Hack Nerd Font, login theme,
`/etc/pam.d/quickshell`, kitty/nvim/starship configs; asks for sudo) and then
the user payload (Hyprland config + scripts, shell, palettes, engines, timex
UI), leaving a complete desktop. `-y` uses the recommended defaults and skips
the 1.37 GB wallpaper pack (a minimal option is planned).

Manual equivalent, step by step:

1. `dots system` — runs [`equisdots/hyprland`](https://github.com/equisdots/hyprland)'s
   installer: distro packages, Hack Nerd Font, login theme (clones
   `equisdots/login` on demand), `/etc/pam.d/quickshell`, kitty/nvim/starship
   configs from their repos. Asks for sudo. Add `-y` for a fully
   non-interactive run.
2. `dots install` — clones the org under `~/.local/share/equisdots` and places
   the user payload (Hyprland config + scripts, shell, palettes, engines,
   timex UI). It also installs the `dots` wrapper and the monthly updater
   timer.
3. `dots doctor` — verifies binaries, repo clones and installed paths. The
   xwww wallpaper daemon (fork of awww) is installed by `dots system` from the
   checksum-verified prebuilt release (source fallback with rust); the
   standalone installer is `scripts/install-xwww.sh` (`FORCE_XWWW=1` on the
   hyprland installer reinstalls an existing one).

## Remote install

No need to clone first — the script clones the whole org itself:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/equisdots/dots/main/dots) setup -y
bash <(curl -fsSL https://raw.githubusercontent.com/equisdots/dots/main/dots) doctor
```

After the first run, `dots` is available at `~/.local/bin/dots` and every repo
lives in `~/.local/share/equisdots`. The requirements below must already be
present. System-level steps that need sudo (packages, fonts, login theme, PAM,
xwww) are handled by
[`equisdots/hyprland`](https://github.com/equisdots/hyprland)'s `install.sh`
or manually.

## Requirements

`git`, `rsync`, `jq`, `hyprland` and `quickshell` (`qs`), plus:

- `xwww-daemon` — wallpaper daemon; use [x-ports/xwww](https://github.com/x-ports/xwww)
  (fork of awww with the extra transitions) or `./scripts/install-xwww.sh`
  to build and install it from source
- `mpvpaper` — video wallpapers (davincix)
- `Hack Nerd Font` — UI glyphs

`dots doctor` reports what is missing.

## License

MIT — see [LICENSE](LICENSE).

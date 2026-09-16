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

Repos are cloned under `~/.local/share/equisdots/<repo>`.

## Usage

```sh
git clone https://github.com/equisdots/dots.git
cd dots
./dots system      # packages, fonts, SDDM theme, PAM, external configs (sudo)
./dots install     # clone/update every repo and place it
./dots doctor      # check dependencies and paths
./dots list        # repo status (clean / dirty / missing)
./dots update      # pull everything and re-apply
./dots uninstall   # remove the created links only
```

`install` never deletes your live config: it copies over it and keeps your
`settings.json` untouched. For a full purge you must remove `~/.config/hypr`
yourself.

### Fresh machine

1. `dots system` — runs `equisdots/hyprland`'s installer: distro packages,
   Hack Nerd Font, SDDM theme, `/etc/pam.d/quickshell`, kitty/nvim/starship
   configs from their repos. Asks for sudo.
2. `dots install` — clones the org under `~/.local/share/equisdots` and places
   the user payload (Hyprland config + scripts, shell, palettes, engines,
   timex UI).
3. `dots doctor` — verifies binaries and installed paths. Build the wallpaper
   daemon with `scripts/install-xwww.sh` if `xwww-daemon` is missing.

## Remote install

No need to clone first — the script clones the whole org itself:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/equisdots/dots/main/dots) install
bash <(curl -fsSL https://raw.githubusercontent.com/equisdots/dots/main/dots) doctor
```

The requirements below must already be present. System-level steps that need
sudo (packages, fonts, SDDM theme, PAM, xwww) are handled by
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

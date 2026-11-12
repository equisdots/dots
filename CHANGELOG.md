# Changelog

## Unreleased

- Rename the wallpaper kernel repository to `equisdots/davinci` and install it under `~/.local/share/equisdots/davinci`.
- Migrate an existing `~/.local/share/equisdots/davinci` clone on install/update, keep `~/.local/bin/davinci` as a compatibility wrapper, and remove the stale clone on reset.
- Fix `dots plugins enable/disable`: resolve the manifest `toggle`/`scope` and write the plugin's own `settings.json`, matching the shell scanner instead of the legacy core `settings.json → plugins.<id>.enabled`.
- Add `dots plugins migrate` (also run automatically) to remove the legacy core toggle mirror while preserving `plugins.<id>.config`, plus a regression test in `tests/plugins-toggle.sh`.


All notable changes to the equisdots meta installer and updater are documented
here. Dates use YYYY-MM-DD.

## [2026-11-01]

### Added
- **0.57 doctor checks**: `dots doctor` now runs `hyprctl configerrors` (fatal),
  `hyprctl deprecated-config` (warning) and warns about a leftover
  `hyprland.conf` on Hyprland 0.57+. The checks are skipped cleanly when
  `hyprctl` is missing or no session is reachable.

### Fixed
- **Plugin hub branch fallback**: when the recorded plugin branch no longer
  exists, follow `main` and switch the managed checkout instead of warning on
  every update.

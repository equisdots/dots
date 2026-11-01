# Changelog

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

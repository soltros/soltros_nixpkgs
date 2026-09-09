# Changelog

All notable changes to the packages in this repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- **addwater**: Enabled `strict=False` in Python's `ConfigParser` when scanning browser profiles (`src/apps/firefox/firefox_details.py`). This fixes a startup crash (`DuplicateOptionError`) when encountering `profiles.ini` files with duplicate keys (e.g. Waterfox or migrated Firefox profiles).
- **addwater**: Expanded package smoke test fixture in `smoke.py` to assert correct discovery when `profiles.ini` contains duplicate keys.

---

## [2026-09-09]

### Added
- **addwater**: Initial native package of Add Water 1.3 (`pkgs/addwater/default.nix`) ported from Flatpak with XDG config directory resolution, autostart path patches, and native smoke test suite.
- **pantheon-studio**: Expanded Pantheon Studio with launcher folders, panel customization, and companion NixOS desktop module (`modules/pantheon-studio.nix`).
- **pantheon-studio**: Added initial desktop application editor and package (`pkgs/pantheon-studio`).
- **termsmith**: Added per-profile icon browser support (`pkgs/termsmith`).
- **waterfox**: Added official binary package for x86_64 and ARM64 Linux (`pkgs/waterfox.nix`).
- **chatgpt**: Added desktop client package (`pkgs/chatgpt.nix`).

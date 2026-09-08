# Pantheon Studio

A native Vala, GTK 4, and Granite application for editing application display names,
icons, and menu visibility. Search the application list, select an entry, edit its
fields, and choose Save Changes. Hidden entries remain in the editor so they can
be shown again. Unsaved edits are discarded when selecting another application.

## Build and run

```sh
nix build .#pantheon-studio
nix run .#pantheon-studio
```

The flake exposes the package for x86_64-linux and aarch64-linux and through
`overlays.default`. Add `pkgs.pantheon-studio` to `environment.systemPackages`
when using the overlay. The build runs isolated desktop-entry roundtrip tests.

## Storage and restoration

Overrides live in `$XDG_DATA_HOME/applications` (normally
`~/.local/share/applications`). Recovery records live in
`$XDG_STATE_HOME/pantheon-studio/backups` (normally
`~/.local/state/pantheon-studio/backups`). Keep these records until you restore
changes. Restore Defaults restores the exact pre-edit local file, or removes
our override when there was no local file, exposing the current system entry.
Uninstalling the app does not remove overrides; restore them first if desired.

Executable commands, desktop actions, and unrelated keys are preserved. Custom
names replace translated Name fields in the override; restoration recovers them.
Custom icon files are referenced in place and should remain at their chosen path.
Edits may also appear in other launchers or docks that read desktop entries.

Nix-managed symlinks are rejected. Changes made outside this app are detected
before subsequent saves or restoration. If a conflict occurs, review the desktop
file and its recovery record manually; the app does not force an overwrite.
User overrides can mask future upstream desktop-entry changes until restored.

## Scope

Version 0.1 edits application entries. Folder organization, launcher-button
appearance, and Wingpanel layout controls are not implemented. Those require
investigation against the target Pantheon version and potentially companion
launcher/panel packages. This package does not replace desktop components.

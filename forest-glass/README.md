# Forest Glass rice (GNOME 50.4 · Forge · Wayland)

Backup of everything changed: `~/.config/gnome-rice-backups/20261020-233807/`
(`MANIFEST.tsv` lists each file/dconf key with its phase; `files/`, `dconf/*.orig`
hold originals; `snapshots/` holds pre-rice dconf dumps, keybindings, wallpaper hash.)

## Layout
| Path | Purpose |
|---|---|
| `src/forest-glass-shell.css` | The only shell CSS you edit (panel, monitor, menus, Quick Settings, calendar, notifications, overview, app grid, dialogs, OSD, lock screen) |
| `src/gtk4.css`, `src/gtk3.css` | Sources for `~/.config/gtk-4.0/gtk.css` / `gtk-3.0/gtk.css` |
| `bin/build-shell-theme.sh` | Stock GNOME dark CSS (re-extracted from the installed shell) + layer → `ForestShell/gnome-shell/gnome-shell.css`; validates, live-reloads, auto-reverts on errors |
| `bin/apply-arcmenu.sh` | Phase A/C ArcMenu keys |
| `bin/apply-forge-colors.sh` | Phase B Forge colours (colours only) |
| `src/system-monitor-panel.css` | System Monitor module + dropdown styling, inserted as a marked block into the extension's own `stylesheet.css` |
| `bin/apply-waybar-modules.sh` | Phase W (round 2, Waybar-style modules): monitor stylesheet block + 1-line `extension.js` class patch, Pamac symbolic icons, battery %, Space Bar + ArcMenu settings |
| `bin/apply-launcher.sh` | Phase L: ArcMenu standalone runner, centered, on Super+D |
| `bin/apply-gtk.sh` | Phase D GTK CSS, gtk-theme, icon-theme, monospace font |
| `bin/apply-tidy-extensions.sh` | Phase T: drop x11gestures (X11-only) and two uninstalled UUIDs from enabled-extensions |
| `bin/init-backup.sh` | New timestamped backup dir + pre-rice snapshots (run first on a fresh install) |
| `bin/sync-to-dotfiles.sh` | Copy tooling + exported rice settings into `~/.dotfiles/forest-glass/` (no commit) |
| `bin/verify.sh` | Read-only health check (wallpaper, Forge/shortcuts, extensions, monitors, CSS, logs) |
| `bin/rollback.sh` | Conflict-aware restore from the manifest |
| `bin/reload-shell-theme.sh` | Live-reload the shell theme on Wayland (no logout) |

All apply scripts are idempotent. After a GNOME update, run `bin/build-shell-theme.sh`
to rebase the theme on the new stock stylesheet.

## Rollback
```bash
~/.config/forest-glass/bin/rollback.sh --dry-run      # preview everything
~/.config/forest-glass/bin/rollback.sh                # whole rice
~/.config/forest-glass/bin/rollback.sh --phase A      # shell theme file + ArcMenu button
~/.config/forest-glass/bin/rollback.sh --phase B      # Forge colours
~/.config/forest-glass/bin/rollback.sh --phase C      # ArcMenu menu/search radius
~/.config/forest-glass/bin/rollback.sh --phase D      # GTK css, gtk/icon theme, mono font
~/.config/forest-glass/bin/rollback.sh --phase W      # round-2 extension-side changes (see below)
~/.config/forest-glass/bin/rollback.sh --phase L      # Super+D Rofi-style launcher (ArcMenu runner)
~/.config/forest-glass/bin/rollback.sh --phase X      # Blur My Shell (uninstall + reset its keys)
~/.config/forest-glass/bin/rollback.sh --phase T      # re-add tidied enabled-extensions entries
```
Anything changed after the rice is reported as CONFLICT and left alone; add `--force`
to restore it anyway. Backups are never deleted. Note: the shell theme file carries
the panel *and* overview/app-grid styling, so `--phase A` reverts all shell visuals.
Manual fallback: `cp -a ~/.config/gnome-rice-backups/20261020-233807/files/<path> ~/<path>`
and `dconf write <key> "$(cat .../dconf/<key-id>.orig)"` (empty .orig → `dconf reset <key>`).

## Round 2: Waybar-style panel modules
Each panel item is a module (monospace text, icon + text in one colour, 2px underline,
10px gaps), after GarroNinja/gruvbox-hyprland's Waybar. Findings that shaped it:
* GNOME 50's St ranks an **extension's own stylesheet above the shell theme** for that
  extension's widgets, even against `!important`. So System Monitor is styled inside its
  stylesheet (marked block), Space Bar via its appearance settings + custom-styles, and
  ArcMenu via its colour settings. The shell theme handles the clock, Quick Settings,
  battery, Pamac and the module underline on ArcMenu's container.
* St paints all four border sides in one colour: underlines use a uniform `border-color`
  with `border-width` only on the bottom.
* System Monitor per-metric colours need the `extension.js` class patch, which GNOME loads
  only at login. If the extension updates, re-run `bin/apply-waybar-modules.sh`.
* To go back to the round-1 panel only: copy `<backup>/layers/forest-glass-shell.round1.css`
  over `src/forest-glass-shell.css`, run `bin/build-shell-theme.sh`, then `rollback.sh --phase W`.
  (ArcMenu hover/active colours were first set in phase A, so phase A restores their originals.)

## Fresh install (from ~/.dotfiles)
```bash
cp -r ~/.dotfiles/forest-glass/{bin,src,README.md} ~/.config/forest-glass/   # mkdir -p it first
~/.config/forest-glass/bin/init-backup.sh          # snapshots + backup dir (always first)
~/.config/forest-glass/bin/build-shell-theme.sh    # A: shell theme (needs the ForestShell dir + User Themes)
~/.config/forest-glass/bin/apply-arcmenu.sh        # A/C
~/.config/forest-glass/bin/apply-forge-colors.sh   # B
~/.config/forest-glass/bin/apply-gtk.sh            # D
~/.config/forest-glass/bin/apply-waybar-modules.sh # W (needs System Monitor Panel installed)
~/.config/forest-glass/bin/apply-launcher.sh       # L
~/.config/forest-glass/bin/apply-blur.sh           # X (installs Blur My Shell; confirm GNOME's dialog)
~/.config/forest-glass/bin/verify.sh
```
Then log out and back in once. `dconf/rice-settings.ini` in the dotfiles is a reference
export of the managed keys (`dconf load / < rice-settings.ini`). To refresh the dotfiles
copy after changes: `~/.config/forest-glass/bin/sync-to-dotfiles.sh`, then commit.

# Keyboard shortcuts — live cheatsheet

Generated from the running session by `~/.config/forest-glass/bin/shortcuts.py`. Re-run it after changing any binding.

192 bound actions, 87 unbound, 0 conflicting accelerator(s), 12 numpad-only binding(s).

## Live test results

Typed on a virtual keyboard by `bin/test-shortcuts.py` (safe subset; lock, shutdown and logout are never sent).

| Keys | Action | Result | Observed |
|---|---|---|---|
| `Volume Up / Down keys` | volume-up/-down | ✅ pass | 0.52 → 0.58 → 0.52 |
| `Super+F3 / Super+F2` | custom: brightness +/- | ✅ pass | 108000 → 120000 → 108000 |
| `Super (tap)` | ArcMenu (overlay key) | ✅ pass | top-left region changed by 20.7 |
| `Super+D` | ArcMenu runner | ✅ pass | centre region changed by 9.9 |
| `Super+X (twice)` | Forge focus-border-toggle | ✅ pass | false → true → false |
| `Super+End` | switch-to-workspace-last | ✅ pass | 3 test windows up, C focused, tiled=False |
| `Super+KP_1 / Super+KP_3` | Forge focus left / right | ✅ pass | focus C → A → B |
| `Super+C (twice)` | Forge window-toggle-float | ✅ pass | (912, 476) → (1248, 786) → (912, 476) |
| `Super+Q` | close window | ✅ pass | window B closed |
| `Alt+F4` | close window | ✅ pass | window A closed |
| `Super+1` | switch-to-workspace-1 | ✅ pass | Space Bar lime block x: 99 → 53 |

## Windows & workspaces (GNOME)

| Shortcut | Action | What it does |
|---|---|---|
| `Alt+space` | activate-window-menu | Activate the window menu |
| `Alt+F7` | begin-move | Move window |
| `Alt+F8` | begin-resize | Resize window |
| `Super+q` / `Alt+F4` | close | Close window |
| `Alt+F6` | cycle-group | Switch windows of an app directly |
| `Shift+Alt+F6` | cycle-group-backward | Reverse switch windows of an app directly |
| `Ctrl+Alt+Escape` | cycle-panels | Switch system controls directly |
| `Shift+Ctrl+Alt+Escape` | cycle-panels-backward | Reverse switch system controls directly |
| `Alt+Escape` | cycle-windows | Switch windows directly |
| `Shift+Alt+Escape` | cycle-windows-backward | Reverse switch windows directly |
| `Super+Shift+Down` | move-to-monitor-down | Move window to the next monitor below |
| `Super+Shift+Left` | move-to-monitor-left | Move window to the next monitor on the left |
| `Super+Shift+Right` | move-to-monitor-right | Move window to the next monitor on the right |
| `Super+Shift+Up` | move-to-monitor-up | Move window to the next monitor above |
| `Shift+Super+1` | move-to-workspace-1 | Move window to workspace 1 |
| `Shift+Super+0` | move-to-workspace-10 | Move window to workspace 10 |
| `Shift+Super+2` | move-to-workspace-2 | Move window to workspace 2 |
| `Shift+Super+3` | move-to-workspace-3 | Move window to workspace 3 |
| `Shift+Super+4` | move-to-workspace-4 | Move window to workspace 4 |
| `Shift+Super+5` | move-to-workspace-5 | Move window to workspace 5 |
| `Shift+Super+6` | move-to-workspace-6 | Move window to workspace 6 |
| `Shift+Super+7` | move-to-workspace-7 | Move window to workspace 7 |
| `Shift+Super+8` | move-to-workspace-8 | Move window to workspace 8 |
| `Shift+Super+9` | move-to-workspace-9 | Move window to workspace 9 |
| `Ctrl+Shift+Alt+Down` | move-to-workspace-down | Move window one workspace down |
| `Super+Shift+End` | move-to-workspace-last | Move window to last workspace |
| `Super+Shift+Page_Up` / `Super+Shift+Alt+Left` / `Ctrl+Shift+Alt+Left` | move-to-workspace-left | Move window one workspace to the left |
| `Super+Shift+Page_Down` / `Super+Shift+Alt+Right` / `Ctrl+Shift+Alt+Right` | move-to-workspace-right | Move window one workspace to the right |
| `Ctrl+Shift+Alt+Up` | move-to-workspace-up | Move window one workspace up |
| `Alt+F1` | panel-main-menu | DEPRECATED: This key is deprecated and ignored. |
| `Alt+F2` | panel-run-dialog | Show the run command prompt |
| `Super+Tab` / `Alt+Tab` | switch-applications | Switch applications |
| `Shift+Super+Tab` / `Shift+Alt+Tab` | switch-applications-backward | Reverse switch applications |
| `Super+Above_Tab` / `Alt+Above_Tab` | switch-group | Switch windows of an application |
| `Shift+Super+Above_Tab` / `Shift+Alt+Above_Tab` | switch-group-backward | Reverse switch windows of an application |
| `Super+space` / `XF86Keyboard` | switch-input-source | Switch input source |
| `Shift+Super+space` / `Shift+XF86Keyboard` | switch-input-source-backward | Switch input source backward |
| `Ctrl+Alt+Tab` | switch-panels | Switch system controls |
| `Shift+Ctrl+Alt+Tab` | switch-panels-backward | Reverse switch system controls |
| `Super+1` | switch-to-workspace-1 | Switch to workspace 1 |
| `Super+0` | switch-to-workspace-10 | Switch to workspace 10 |
| `Super+2` | switch-to-workspace-2 | Switch to workspace 2 |
| `Super+3` | switch-to-workspace-3 | Switch to workspace 3 |
| `Super+4` | switch-to-workspace-4 | Switch to workspace 4 |
| `Super+5` | switch-to-workspace-5 | Switch to workspace 5 |
| `Super+6` | switch-to-workspace-6 | Switch to workspace 6 |
| `Super+7` | switch-to-workspace-7 | Switch to workspace 7 |
| `Super+8` | switch-to-workspace-8 | Switch to workspace 8 |
| `Super+9` | switch-to-workspace-9 | Switch to workspace 9 |
| `Ctrl+Alt+Down` | switch-to-workspace-down | Switch to workspace below |
| `Super+End` | switch-to-workspace-last | Switch to last workspace |
| `Super+Page_Up` / `Super+Alt+Left` / `Ctrl+Alt+Left` | switch-to-workspace-left | Switch to workspace left |
| `Super+Page_Down` / `Super+Alt+Right` / `Ctrl+Alt+Right` | switch-to-workspace-right | Switch to workspace right |
| `Ctrl+Alt+Up` | switch-to-workspace-up | Switch to workspace above |
| `Alt+F10` | toggle-maximized | Toggle maximization state |
| `Super+Down` / `Alt+F5` | unmaximize | Restore window |

## Shell (GNOME)

| Shortcut | Action | What it does |
|---|---|---|
| `Super+n` | focus-active-notification | Keybinding to focus the active notification |
| `Super+Ctrl+1` | open-new-window-application-1 | Open a new instance of application 1 |
| `Super+Ctrl+2` | open-new-window-application-2 | Open a new instance of application 2 |
| `Super+Ctrl+3` | open-new-window-application-3 | Open a new instance of application 3 |
| `Super+Ctrl+4` | open-new-window-application-4 | Open a new instance of application 4 |
| `Super+Ctrl+5` | open-new-window-application-5 | Open a new instance of application 5 |
| `Super+Ctrl+6` | open-new-window-application-6 | Open a new instance of application 6 |
| `Super+Ctrl+7` | open-new-window-application-7 | Open a new instance of application 7 |
| `Super+Ctrl+8` | open-new-window-application-8 | Open a new instance of application 8 |
| `Super+Ctrl+9` | open-new-window-application-9 | Open a new instance of application 9 |
| `Super (tap)` | overlay-key | Activities overview (or ArcMenu when it claims Super) _(Taken over by ArcMenu (arcmenu-hotkey-overlay-key-enabled))_ |
| `XF86MonBrightnessCycle` | screen-brightness-cycle | Screen brightness cycle |
| `Shift+XF86MonBrightnessCycle` | screen-brightness-cycle-monitor | Screen brightness cycle on current monitor |
| `XF86MonBrightnessDown` | screen-brightness-down | Screen brightness down |
| `Shift+XF86MonBrightnessDown` | screen-brightness-down-monitor | Screen brightness down on current monitor |
| `XF86MonBrightnessUp` | screen-brightness-up | Screen brightness up |
| `Shift+XF86MonBrightnessUp` | screen-brightness-up-monitor | Screen brightness up on current monitor |
| `Shift+Print` | screenshot | Take a screenshot |
| `Alt+Print` | screenshot-window | Take a screenshot of a window |
| `Super+Alt+Down` | shift-overview-down | Keybinding to shift between overview states |
| `Super+Alt+Up` | shift-overview-up | Keybinding to shift between overview states |
| `Ctrl+Shift+Alt+R` | show-screen-recording-ui | Record a screencast interactively |
| `Print` | show-screenshot-ui | Take a screenshot interactively |
| `Super+a` | toggle-application-view | Keybinding to open the “Show Applications” view |
| `Super+s` | toggle-quick-settings | Keybinding to toggle the quick settings menu |

## Tiling & monitors (Mutter)

| Shortcut | Action | What it does |
|---|---|---|
| `Super+Shift+Escape` | cancel-input-capture | Cancel any active input capture session |
| `XF86RotateWindows` | rotate-monitor | Rotates the built-in monitor configuration |
| `Super+p` / `XF86Display` | switch-monitor | Switch monitor configurations |
| `Super+Left` | toggle-tiled-left | View split on left |
| `Super+Right` | toggle-tiled-right | View split on right |

## Wayland session (Mutter)

| Shortcut | Action | What it does |
|---|---|---|
| `Super+Escape` | restore-shortcuts | Re-enable shortcuts |
| `Ctrl+Alt+F1` | switch-to-session-1 | Switch to VT 1 |
| `Ctrl+Alt+F10` | switch-to-session-10 | Switch to VT 10 |
| `Ctrl+Alt+F11` | switch-to-session-11 | Switch to VT 11 |
| `Ctrl+Alt+F12` | switch-to-session-12 | Switch to VT 12 |
| `Ctrl+Alt+F2` | switch-to-session-2 | Switch to VT 2 |
| `Ctrl+Alt+F3` | switch-to-session-3 | Switch to VT 3 |
| `Ctrl+Alt+F4` | switch-to-session-4 | Switch to VT 4 |
| `Ctrl+Alt+F5` | switch-to-session-5 | Switch to VT 5 |
| `Ctrl+Alt+F6` | switch-to-session-6 | Switch to VT 6 |
| `Ctrl+Alt+F7` | switch-to-session-7 | Switch to VT 7 |
| `Ctrl+Alt+F8` | switch-to-session-8 | Switch to VT 8 |
| `Ctrl+Alt+F9` | switch-to-session-9 | Switch to VT 9 |

## System, media & launchers

| Shortcut | Action | What it does |
|---|---|---|
| `XF86Battery` | battery-status-static | Show battery status |
| `XF86Calculator` | calculator-static | Launch calculator |
| `XF86Tools` | control-center-static | Launch settings |
| `XF86Eject` | eject-static | Eject |
| `XF86Mail` | email-static | Launch email client |
| `Super+F1` | help | Launch help browser |
| `XF86Suspend` / `XF86Hibernate` | hibernate-static | Hibernate button |
| `XF86Explorer` | home-static | Home folder |
| `XF86KbdBrightnessDown` | keyboard-brightness-down-static | Keyboard brightness down |
| `XF86KbdLightOnOff` | keyboard-brightness-toggle-static | Keyboard brightness toggle |
| `XF86KbdBrightnessUp` | keyboard-brightness-up-static | Keyboard brightness up |
| `Ctrl+Alt+Delete` | logout | Log out |
| `Alt+Super+8` | magnifier | Toggle magnifier |
| `Alt+Super+equal` | magnifier-zoom-in | Magnifier zoom in |
| `Alt+Super+minus` | magnifier-zoom-out | Magnifier zoom out |
| `XF86AudioMedia` | media-static | Launch media player |
| `XF86AudioMicMute` | mic-mute-static | Microphone mute/unmute |
| `XF86AudioNext` / `Ctrl+XF86AudioNext` | next-static | Next track |
| `XF86AudioPause` | pause-static | Pause playback |
| `XF86AudioPlay` / `Ctrl+XF86AudioPlay` | play-static | Play (or play/pause) |
| `XF86AudioForward` | playback-forward-static | Skip forward in current track |
| `XF86AudioRandomPlay` | playback-random-static | Toggle random playback mode |
| `XF86AudioRepeat` | playback-repeat-static | Toggle repeat playback mode |
| `XF86AudioRewind` | playback-rewind-static | Skip backward in current track |
| `XF86PowerOff` | power-static | Power button |
| `XF86AudioPrev` / `Ctrl+XF86AudioPrev` | previous-static | Previous track |
| `XF86Bluetooth` | rfkill-bluetooth-static | Bluetooth RF kill |
| `XF86WLAN` / `XF86UWB` / `XF86RFKill` | rfkill-static | RF kill |
| `Super+o` / `XF86RotationLockToggle` | rotate-video-lock-static | Toggle automatic screen orientation |
| `Alt+Super+s` | screenreader | Toggle screen reader |
| `Super+Shift+l` | screensaver | Lock screen |
| `XF86ScreenSaver` | screensaver-static | Lock screen |
| `XF86Search` | search-static | Search |
| `XF86AudioStop` | stop-static | Stop playback |
| `XF86Sleep` | suspend-static | Suspend button |
| `XF86TouchpadOff` | touchpad-off-static | Switch touchpad off |
| `XF86TouchpadOn` | touchpad-on-static | Switch touchpad on |
| `XF86TouchpadToggle` / `Ctrl+Super+XF86TouchpadToggle` | touchpad-toggle-static | Magnifier zoom out |
| `Shift+XF86AudioLowerVolume` / `Ctrl+Shift+XF86AudioLowerVolume` | volume-down-precise-static | Precise volume down |
| `Alt+XF86AudioLowerVolume` / `Alt+Ctrl+XF86AudioLowerVolume` | volume-down-quiet-static | Quiet volume down |
| `XF86AudioLowerVolume` / `Ctrl+XF86AudioLowerVolume` | volume-down-static | Volume down |
| `Alt+XF86AudioMute` | volume-mute-quiet-static | Quiet volume mute/unmute |
| `XF86AudioMute` | volume-mute-static | Volume mute/unmute |
| `Shift+XF86AudioRaiseVolume` / `Ctrl+Shift+XF86AudioRaiseVolume` | volume-up-precise-static | Precise volume up |
| `Alt+XF86AudioRaiseVolume` / `Alt+Ctrl+XF86AudioRaiseVolume` | volume-up-quiet-static | Quiet volume up |
| `XF86AudioRaiseVolume` / `Ctrl+XF86AudioRaiseVolume` | volume-up-static | Volume up |
| `XF86WWW` | www-static | Launch web browser |

## Forge tiling

| Shortcut | Action | What it does |
|---|---|---|
| `Super+z` | con-split-horizontal | Split a container horizontally |
| `Super+g` | con-split-layout-toggle | Toggle split layout: horizontal or vertical |
| `Super+v` | con-split-vertical | Split a container vertically |
| `Shift+Super+s` | con-stacked-layout-toggle | Toggle stacked layout |
| `Shift+Super+t` | con-tabbed-layout-toggle | Toggle tabbed layout |
| `Ctrl+Alt+y` | con-tabbed-showtab-decoration-toggle | Toggle showing the tab decoration layout |
| `Super+x` | focus-border-toggle | Toggle the focused window's border |
| `Super+Period` | prefs-open | Open the extension's preferences |
| `Super+w` | prefs-tiling-toggle | Toggle tiling mode on/off |
| `Super+KP_2` | window-focus-down | Move window down |
| `Super+KP_1` | window-focus-left | Move window left |
| `Super+KP_3` | window-focus-right | Move window right |
| `Super+KP_5` | window-focus-up | Move window up |
| `Ctrl+Super+minus` | window-gap-size-decrease | Decrease the size of gaps between windows/cons |
| `Ctrl+Super+plus` | window-gap-size-increase | Increase the size of gaps between windows/cons |
| `Shift+Super+KP_2` | window-move-down | Move window down |
| `Shift+Super+KP_1` | window-move-left | Move window left |
| `Shift+Super+KP_3` | window-move-right | Move window right |
| `Shift+Super+KP_5` | window-move-up | Move window up |
| `Shift+Ctrl+Super+i` | window-resize-bottom-decrease |  |
| `Ctrl+Super+u` | window-resize-bottom-increase |  |
| `Shift+Ctrl+Super+o` | window-resize-left-decrease |  |
| `Ctrl+Super+y` | window-resize-left-increase |  |
| `Shift+Ctrl+Super+y` | window-resize-right-decrease |  |
| `Ctrl+Super+o` | window-resize-right-increase |  |
| `Shift+Ctrl+Super+u` | window-resize-top-decrease |  |
| `Ctrl+Super+i` | window-resize-top-increase |  |
| `Ctrl+Alt+c` | window-snap-center |  |
| `Ctrl+Alt+d` | window-snap-one-third-left |  |
| `Ctrl+Alt+g` | window-snap-one-third-right |  |
| `Ctrl+Alt+e` | window-snap-two-third-left |  |
| `Ctrl+Alt+t` | window-snap-two-third-right |  |
| `Ctrl+Super+KP_2` | window-swap-down | Swap window down |
| `Super+Return` | window-swap-last-active | Swap the last active window with the current one |
| `Ctrl+Super+KP_1` | window-swap-left | Swap window left |
| `Ctrl+Super+KP_3` | window-swap-right | Swap window right |
| `Ctrl+Super+KP_5` | window-swap-up | Swap window up |
| `Shift+Super+c` | window-toggle-always-float |  |
| `Super+c` | window-toggle-float | Toggle window float |
| `Shift+Super+w` | workspace-active-tile-toggle | Toggle active workspace tiling |

## ArcMenu launcher

| Shortcut | Action | What it does |
|---|---|---|
| `Super (tap)` | arcmenu-hotkey | Keybind to open ArcMenu _(ArcMenu takes over the Super key (replaces the overview))_ |
| `Super+d` | runner-hotkey | Keybind to open standalone runner menu. Setting a keybind enables the standalone runner menu. |

## Space Bar workspaces

| Shortcut | Action | What it does |
|---|---|---|
| `Ctrl+Alt+Super+Left` | move-workspace-left |  |
| `Ctrl+Alt+Super+Right` | move-workspace-right |  |

## Custom commands

| Shortcut | Action | What it does |
|---|---|---|
| `Super+F2` | Decrease Brightness | brightnessctl set 10%- |
| `Super+F3` | Increase Brightness | brightnessctl set +10% |

## Defined but switched off

These are configured but do not fire, because the owning feature is disabled.

| Shortcut | Owner / action | Why inactive |
|---|---|---|
| `Ctrl+Super+1` | Dash to Dock: app-ctrl-hotkey-1 | Dash to Dock hot-keys off |
| `Ctrl+Super+0` | Dash to Dock: app-ctrl-hotkey-10 | Dash to Dock hot-keys off |
| `Ctrl+Super+2` | Dash to Dock: app-ctrl-hotkey-2 | Dash to Dock hot-keys off |
| `Ctrl+Super+3` | Dash to Dock: app-ctrl-hotkey-3 | Dash to Dock hot-keys off |
| `Ctrl+Super+4` | Dash to Dock: app-ctrl-hotkey-4 | Dash to Dock hot-keys off |
| `Ctrl+Super+5` | Dash to Dock: app-ctrl-hotkey-5 | Dash to Dock hot-keys off |
| `Ctrl+Super+6` | Dash to Dock: app-ctrl-hotkey-6 | Dash to Dock hot-keys off |
| `Ctrl+Super+7` | Dash to Dock: app-ctrl-hotkey-7 | Dash to Dock hot-keys off |
| `Ctrl+Super+8` | Dash to Dock: app-ctrl-hotkey-8 | Dash to Dock hot-keys off |
| `Ctrl+Super+9` | Dash to Dock: app-ctrl-hotkey-9 | Dash to Dock hot-keys off |
| `Super+1` | Dash to Dock: app-hotkey-1 | Dash to Dock hot-keys off |
| `Super+0` | Dash to Dock: app-hotkey-10 | Dash to Dock hot-keys off |
| `Super+2` | Dash to Dock: app-hotkey-2 | Dash to Dock hot-keys off |
| `Super+3` | Dash to Dock: app-hotkey-3 | Dash to Dock hot-keys off |
| `Super+4` | Dash to Dock: app-hotkey-4 | Dash to Dock hot-keys off |
| `Super+5` | Dash to Dock: app-hotkey-5 | Dash to Dock hot-keys off |
| `Super+6` | Dash to Dock: app-hotkey-6 | Dash to Dock hot-keys off |
| `Super+7` | Dash to Dock: app-hotkey-7 | Dash to Dock hot-keys off |
| `Super+8` | Dash to Dock: app-hotkey-8 | Dash to Dock hot-keys off |
| `Super+9` | Dash to Dock: app-hotkey-9 | Dash to Dock hot-keys off |
| `Shift+Super+1` | Dash to Dock: app-shift-hotkey-1 | Dash to Dock hot-keys off |
| `Shift+Super+0` | Dash to Dock: app-shift-hotkey-10 | Dash to Dock hot-keys off |
| `Shift+Super+2` | Dash to Dock: app-shift-hotkey-2 | Dash to Dock hot-keys off |
| `Shift+Super+3` | Dash to Dock: app-shift-hotkey-3 | Dash to Dock hot-keys off |
| `Shift+Super+4` | Dash to Dock: app-shift-hotkey-4 | Dash to Dock hot-keys off |
| `Shift+Super+5` | Dash to Dock: app-shift-hotkey-5 | Dash to Dock hot-keys off |
| `Shift+Super+6` | Dash to Dock: app-shift-hotkey-6 | Dash to Dock hot-keys off |
| `Shift+Super+7` | Dash to Dock: app-shift-hotkey-7 | Dash to Dock hot-keys off |
| `Shift+Super+8` | Dash to Dock: app-shift-hotkey-8 | Dash to Dock hot-keys off |
| `Shift+Super+9` | Dash to Dock: app-shift-hotkey-9 | Dash to Dock hot-keys off |
| `Super+q` | Dash to Dock: shortcut | Dash to Dock show-dock hotkey off |
| `Super+1` | Space Bar workspaces: activate-1-key | Space Bar: workspace shortcuts switched off |
| `Super+0` | Space Bar workspaces: activate-10-key | Space Bar: workspace shortcuts switched off |
| `Super+2` | Space Bar workspaces: activate-2-key | Space Bar: workspace shortcuts switched off |
| `Super+3` | Space Bar workspaces: activate-3-key | Space Bar: workspace shortcuts switched off |
| `Super+4` | Space Bar workspaces: activate-4-key | Space Bar: workspace shortcuts switched off |
| `Super+5` | Space Bar workspaces: activate-5-key | Space Bar: workspace shortcuts switched off |
| `Super+6` | Space Bar workspaces: activate-6-key | Space Bar: workspace shortcuts switched off |
| `Super+7` | Space Bar workspaces: activate-7-key | Space Bar: workspace shortcuts switched off |
| `Super+8` | Space Bar workspaces: activate-8-key | Space Bar: workspace shortcuts switched off |
| `Super+9` | Space Bar workspaces: activate-9-key | Space Bar: workspace shortcuts switched off |

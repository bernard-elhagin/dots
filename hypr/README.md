# Desktop configuration

Run `./install.sh --desktop-only` from the repository root to install the
Hyprland, Quickshell, Rofi themes, and taskbar menu scripts. The full installer
also performs these steps. Existing files are backed up with timestamped names;
running it again leaves correct links alone.

Hyprland configuration files are linked individually into `~/.config/hypr/`.
`hyprland-gui.lua` contains the HyprMod settings loaded by `hyprland.lua`.
Session snapshots (`session.json`) and other local files stay in that directory
and are not installed or added to the repository. The old `keybinds.lua` and
`saved_session.txt` in this repository are not loaded by the Lua configuration.

The taskbar uses the tracked scripts under `config/waybar/scripts/`, even though
Quickshell draws the panel. Their Rofi themes live under `config/rofi/`.

## Taskbar appearance and restore

`config/quickshell/retro/shell.qml` is the active futuristic taskbar: multicolor
workspace accents, cyan/violet light rails, dark gradient panels, and 2px outer
gaps. The installer links the entire Quickshell directory, including the bar's
status and power-menu helpers. Hyprland starts this configuration with
`qs -n -c retro`.

Workspace tooltips use Expedition character names. The Pomodoro
widget is labeled Gradient Charge and fills a progress meter during each phase;
it uses the bundled Pomodoro app's status fields `remaining` and `duration`.
Restart a timer launched before that status update to enable the meter.

Hover over the clock for the full date, ISO week and timezone; click for the
Lumière Almanac with Monday-first month navigation, a Today button and today's
completed focus sessions. Right-click copies the timestamp using `wl-copy`.
Close the almanac with its × button or Escape.
The bundled Pomodoro app persists its daily count in
`~/.cache/pomodoro/daily.json` (under `$XDG_CACHE_HOME` when configured).
It counts completed focus phases, excludes skipped phases, and resets the
displayed total at local midnight. Restart older running timers to enable daily
tracking; sessions completed before this feature was installed are not recovered.

The previous cyan Retro design is preserved in
`config/quickshell/retro/presets/retro-cyan.qml`. To restore it:

```sh
cp ~/dots/config/quickshell/retro/presets/retro-cyan.qml ~/.config/quickshell/retro/shell.qml
```

Quickshell normally reloads QML edits automatically. Restoring the preset also
changes the repository's active `shell.qml`, since the installed directory is
a symlink.

## Dependencies and machine-specific setup

The package installer's `all` and `desktop` profiles include Hyprland,
Quickshell, Rofi, Hyprpaper, desktop portals, `jq`, NetworkManager (`nmcli`,
`nm-applet`), BlueZ (`bluetoothctl`), Blueman, UPower, PipeWire/WirePlumber
(`wpctl`), `pavucontrol`, `playerctl`, `brightnessctl`, `libnotify`
(`notify-send`), `pacman-contrib` (`checkupdates`), and JetBrains Mono Nerd Font.
They also install the configured launcher applications: Firefox, Xfce Terminal,
Yazi, Dolphin, Neovim and Steam, plus Python, fzf and Wayland clipboard tools.
Steam requires the `[multilib]` repository to be enabled. `yay` and Flatpak
update checks remain optional.

Installing these packages does not enable or replace system services. On a
fresh installation, configure NetworkManager and Bluetooth services and your
PipeWire user session. Existing audio/network choices are left alone; pacman
may ask about replacing conflicting PulseAudio packages. Notifications need a
running notification daemon supplied by your desktop/session. This repository
does not select or start one.
The desktop installer links Mako's configuration, which pins desktop
notifications to `DP-2` rather than following the focused monitor.

The Pomodoro app, its modules, sound assets and tests are bundled under
`apps/pomodoro`. The installer links `bin/pomodoro` to `~/.local/bin/pomodoro`,
which the taskbar invokes. Both `all` and `desktop` package profiles provide
Perl and PipeWire sound playback. No CPAN installation or separate development
checkout is required. Restart a running timer after updating the bundled app.

The Commodore 64 wallpaper is bundled in `hypr/wallpapers/commodore64.jpg`.
The installer links that directory at `~/.config/hypr/wallpapers`, which
`hyprpaper.conf` uses without a hard-coded username. Monitor actions still use
`DP-1` and `DP-2`; adapt them when moving to different hardware.

After installation, run `hyprctl reload` in the desktop session. Quickshell
normally watches its configuration; start it with `qs -n -c retro` if needed.

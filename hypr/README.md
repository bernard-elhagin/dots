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

## Dependencies and machine-specific setup

The package installer provides Hyprland, Quickshell and Rofi. The desktop also
uses `jq`, NetworkManager (`nmcli`, `nm-applet`), BlueZ (`bluetoothctl`),
`blueman-manager`, PipeWire/WirePlumber (`wpctl`), `pavucontrol`, `playerctl`,
`brightnessctl`, `libnotify` (`notify-send`), `pacman-contrib` (`checkupdates`),
and JetBrains Mono/Nerd Font glyphs. `yay` and Flatpak update checks are optional.
Application launchers expect Firefox, Xfce Terminal, Yazi and Neovim; Steam
shortcuts require Steam. Install the applications you use separately.

The Pomodoro widget currently requires the separate project at
`~/Development/Projects/pomodoro/pomodoro`, with its Perl modules and runtime
dependencies. Restore that project separately to reproduce the widget; its
source is not bundled here.

`hyprpaper.conf` refers to `~/Pictures/wallpapers/commodore64.jpg` using the
current machine's absolute home path. Restore that image and adapt the path
for another user. Monitor actions use `DP-1` and `DP-2`; adapt them when moving
to different hardware. These assets and hardware choices are not installed.

After installation, run `hyprctl reload` in the desktop session. Quickshell
normally watches its configuration; start it with `qs -n -c retro` if needed.

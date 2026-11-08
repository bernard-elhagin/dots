---
name: desktop-troubleshooting
description: Diagnose and fix Linux desktop problems involving Hyprland, Quickshell, notifications, PipeWire audio, application startup and session restoration, or OpenRGB lighting. Use for desktop behavior and device integration problems, rather than unrelated application development or general Linux questions.
---

# Desktop troubleshooting

Find the component responsible for the reported behavior, make the smallest
supported fix, and verify it in the running desktop when possible.

## Establish the active setup

Start with the symptom and existing evidence. Inspect the relevant running
process, installed command help, configuration path, and a short log excerpt.
Avoid collecting broad process arguments, environment dumps, notification
history, or unrelated logs that could expose private data.

This user's dotfiles normally live in `~/dots`. Inspect the current repository
instructions and symlinks before editing. Useful starting points, to verify
rather than assume:

- Hyprland: `hypr/hyprland.lua`; this setup uses Lua and `hl` helpers rather
  than only traditional `hyprland.conf` syntax.
- Taskbar: `config/quickshell/retro/shell.qml` and sibling QML components.
  `presets/` contains saved alternatives, not necessarily the active theme.
- Notifications: `config/mako/config`, linked to `~/.config/mako/config`.
  Discover the active notification daemon before applying daemon-specific fixes.
- Desktop helpers: `config/waybar/scripts/`, even when Quickshell draws the bar.
- Installation and packages: `install.sh` and `packages.sh`. Inspect their
  existing behavior before adding dependencies or installation targets.

Confirm output names using `hyprctl monitors -j`. Previously, the second
monitor was `DP-2`; recheck when placement matters. Separate desktop
notifications from taskbar hover labels and application menus when the word
"popup" is ambiguous.

## Diagnose at the relevant boundary

Choose only the checks relevant to the symptom:

- **Hyprland and startup:** inspect the active monitor/workspace state,
  configured startup commands, and the application's actual launch mechanism.
  For restoration failures, check saved state, application identity, and startup
  readiness before adding delays or launching duplicate instances.
- **Quickshell:** inspect popup anchors, focus behavior, input regions, and
  per-screen instances. Informational overlays should not intercept icon clicks.
  Check reload logs with `quickshell log -c retro -t 30` when that config is
  active. Locate the real Qt linter; on this machine it has been
  `/usr/lib/qt6/bin/qmllint`. Interpret unresolved Quickshell type warnings
  alongside the running shell's logs.
- **Notifications:** inspect Mako's current config and `man 5 mako`. Reload
  with `makoctl reload`. Sound is separate from visual styling; check
  `on-notify`, the selected audio player, and the sound file. Send a short
  preview notification only when useful and authorized by the task.
- **Audio:** inspect `wpctl status`, the affected application's stream, mute
  state, volume, and selected sink. Distinguish a missing sound hook from a
  routing problem before restarting services or replacing configuration.
- **RGB:** start with `openrgb --list-detailed`. Its default listing may come
  from an existing SDK server; use `--noautoconnect` when a fresh hardware scan
  is needed. Select the verified controller by name and inspect its supported
  modes before changing it. A device without Off may support Static black
  (`000000`). Keep changes scoped to the requested devices.

For missing RGB RAM, distinguish disabled detection, permissions, absent SMBus
adapters, and firmware conflicts. Inspect loaded `i2c_dev`/`i2c_piix4` modules,
adapter names under `/sys/bus/i2c/devices/`, and device permissions. Request
targeted kernel log context if access requires the user's password. Do not
equate one generic ACPI warning with proof of a particular driver's failure.
Avoid raw I2C writes and undocumented force options. Check current upstream
documentation before proposing an ACPI resource workaround; explain its actual
tradeoff and prefer a reversible one-boot test before persistent boot changes.
Discover the bootloader rather than assuming GRUB.

## Apply and verify

Prefer tracked source files when installed configuration is symlinked into
`~/dots`. Preserve unrelated settings and the user's existing defaults/comments.
Use the installer's backup-aware linking helpers for new managed files; do not
run the full installer just to apply a single unrelated change.

Handle sandbox denial separately from application failure. Use the environment's
approval mechanism for access outside permitted paths or the desktop session.
An approved sandbox escalation does not supply a sudo password. If administrator
access is still blocked, provide the smallest diagnostic command needed from
the user and continue any independent work.

Validate changed shell with `bash -n`, Lua with `luac -p` when applicable, and
configuration through its application's parser/reload. Check focused logs after
reload. Avoid restarting the compositor or logging out as a routine check.

Report what changed, whether it applies now or only at login/reboot, and what
was actually verified. A successful command does not prove that a physical LED
is dark, a sound was audible, or a visual layout looks right. State any remaining
user-observable check plainly. Never claim the issue is fixed while detection
or required verification is still blocked.

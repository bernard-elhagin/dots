# Pomodoro

Bundled with the dotfiles repository. `install.sh` installs a launcher at
`~/.local/bin/pomodoro`; `packages.sh` supplies Perl and PipeWire sound playback.
The taskbar uses this launcher, so no separate development checkout is needed.
Edit the source in `~/dots/apps/pomodoro` to change the installed app.

A small terminal Pomodoro app in Perl, using only modules included with Perl.
Requires Perl 5.10+ on a POSIX system (Linux/macOS), the standard `stty` utility,
and an interactive ANSI terminal with a Unicode-capable font.

The centered dashboard includes a large countdown, a progress bar, and markers
showing progress toward the next long break. Focus is coral, breaks are green,
and pause is amber. It adapts to terminal resizing and uses a compact display in
small windows. Colors can be disabled without losing status information.

```sh
./pomodoro
./pomodoro --work 50 --short 10 --long 30 --every 3
./pomodoro --work 0.1 --short 0.05 --long 0.1 --every 2
```

Defaults: 25 minutes of focus, a 5-minute short break, and a 15-minute long break
after every fourth completed focus session. Phases advance automatically, with a
gentle falling chime when a break starts and a rising chime when focus resumes.
Playback runs in the background so keyboard controls stay responsive.
Use `--silent` to disable all sounds, or `--no-color` to disable colors.

Audio uses the first available player: `pw-play` (PipeWire), `paplay` (PulseAudio),
`afplay` (macOS), or `aplay` (ALSA). If no player is available or playback fails,
the app falls back to the terminal bell; whether that is audible depends on your
terminal settings. Both WAV chimes in `assets/` are original synthesized tones.
Skipping a phase plays the new phase's chime. Resetting a phase does not.

| Key | Action |
| --- | --- |
| Space or P | Pause/resume |
| N | Skip to the next phase |
| R twice within 3 seconds | Restart the current phase |
| Q or Ctrl+C | Quit |

Skipping a focus phase does not count it as completed. Reset affects only the
current phase and preserves pause status. Session counts live in memory and reset
when the app exits. A monotonic clock keeps the countdown stable across wall-clock
adjustments; missed time at a phase boundary is not deducted from the next phase.
Terminal settings and the previous screen are restored on normal exit or handled
signals. As with other terminal apps, SIGKILL cannot be cleaned up; run `stty sane`
if the process is forcibly killed and leaves your terminal without echo.

## Taskbar integration

The local Quickshell retro taskbar displays a live countdown next to the clock.
Click GRADIENT to open the timer in a terminal; click a running countdown to
pause/resume. Keep the terminal open: it owns the timer, while the taskbar displays
its state. The normal terminal controls continue to work.

`./pomodoro --status` prints JSON without requiring a terminal, and
`./pomodoro --toggle` pauses/resumes an existing timer. A process lock prevents
duplicate timers. State is published atomically to
`$XDG_CACHE_HOME/pomodoro/status.json` (default `~/.cache/pomodoro/status.json`);
stale files are treated as stopped and normal exit removes the status file.

Status includes remaining seconds, phase duration, and `completedToday` for the
Gradient Charge meter and Lumière Almanac. Completed focus phases are counted
by local date in `$XDG_CACHE_HOME/pomodoro/daily.json`, surviving timer restarts.
Skipped focus phases do not count; daily totals start again at local midnight.
Runtime state and daily counts are not stored in the dotfiles repository.

## Development

```sh
perl -c pomodoro
prove -v t
```

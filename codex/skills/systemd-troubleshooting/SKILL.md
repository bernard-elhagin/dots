---
name: systemd-troubleshooting
description: Diagnose and fix systemd system or user services, timers, socket activation, unit overrides, dependency ordering, and journal errors. Use for service lifecycle and scheduling problems, rather than unrelated desktop settings or application code.
---

# Systemd troubleshooting

Identify the responsible unit and manager, explain the failure from evidence,
and make the smallest change that restores the intended behavior.

## Identify the manager and trigger

Distinguish system units (`systemctl`) from user units (`systemctl --user`).
Do not assume that an application running in the desktop is a user service;
it may start through Hyprland, XDG autostart, D-Bus, a shell, or another process.
Check the actual launch mechanism before creating an additional service.

Resolve the exact unit name and any instance or aliases. Prefer bounded queries:

```bash
systemctl --user status example.service --no-pager --full
systemctl --user cat example.service
journalctl --user -u example.service -b -n 80 --no-pager
```

Replace the sample unit with the identified unit; omit `--user` for system
services. If access is denied, distinguish session-bus/sandbox access from sudo
requirements. Do not interpret inaccessible journals as an absence of errors.

Inspect relevant properties with `systemctl show`: LoadState, ActiveState,
SubState, Result, ExecMainCode, ExecMainStatus, FragmentPath, DropInPaths, and
the applicable start/stop timestamps. Inspect additional properties only when
they help the diagnosis. Avoid broad environment dumps, credentials, and
unrelated journal content in tool output.

## Diagnose the failure mechanism

- **Launch failure:** check the effective ExecStart, executable availability,
  working directory, configured user/group, file permissions, and required
  configuration. Unit commands do not run in an interactive shell; shell
  operators, expansion, and startup-file PATH settings are not automatic.
  Keep systemd specifier and environment expansion distinct from shell parsing.
- **Application failure:** correlate exit status and journal timestamps with
  the actual application error. Distinguish application exit codes from systemd
  execution failures using the installed documentation.
- **Restart loops:** find the original failure before changing Restart,
  RestartSec, or start limits. `reset-failed` clears recorded failure and rate
  limits; it does not repair the cause. Avoid repeatedly restarting a failing
  service without new evidence.
- **Dependencies:** `After`/`Before` order units but do not pull them in;
  `Wants`/`Requires` pull units in with different failure behavior. Ordering is
  not a guarantee that an external application or network endpoint is ready.
  Inspect Type, readiness signaling, and actual dependencies before adding
  arbitrary sleeps or broad network targets.
- **Activation:** a disabled service can still start through a socket, timer,
  D-Bus, dependency, or manual command. Inspect relevant triggers and reverse
  dependencies. Static units need not be enabled. Do not mask a unit simply to
  silence an unexplained activation.
- **User-session failures:** inspect user-manager environment and graphical
  session integration when display, Wayland, or D-Bus access is missing. Avoid
  hardcoding runtime socket paths or copying an entire interactive environment.
  Enable lingering only when running outside login sessions is intended; it
  changes the user manager's lifetime, not just one service's startup.
- **Timers:** inspect the timer and its associated service, `list-timers --all`,
  timezone, clock synchronization, and OnCalendar versus monotonic scheduling.
  Check Persistent, AccuracySec, and RandomizedDelaySec before concluding that
  a delayed or missed run is a bug. Use `systemd-analyze calendar` for calendar
  expressions. Starting the timer does not prove that its service succeeded.
- **Access restrictions:** inspect relevant sandboxing, filesystem restrictions,
  capabilities, and credential configuration when logs show access failures.
  Do not disable security settings wholesale to make the error disappear.

## Make a focused change

Inspect the merged unit and existing drop-ins first. Prefer an appropriate
drop-in or maintained local unit to editing distribution files under
`/usr/lib/systemd/system`. For user units, use the actual XDG/user unit location.
In `~/dots`, keep reusable configuration tracked and follow the installer's
existing backup-aware symlink conventions when installation is part of the task.

Respect systemd's directive-specific merge behavior. Replacing a single-command
ExecStart usually requires an empty `ExecStart=` before the new value; do not
apply list-reset rules indiscriminately to unrelated directives. Preserve
unrelated settings and avoid `systemctl revert` when it would delete other local
overrides. Consult installed manuals for version-sensitive directives.

Distinguish start from enable, stop from disable, and both from mask. Apply only
the lifecycle change needed for the user's requested outcome. Before restarting
or stopping a service, consider concrete effects such as interrupting the current
network connection, login session, or running job. Do not reboot as a routine
diagnostic step.

## Validate and report

Use `systemd-analyze verify` on changed units where applicable, with `--user`
for user units. Interpret dependency warnings in context; validation is not a
substitute for exercising the service. Validate application configuration with
its own checker when available.

After unit or drop-in changes, reload the correct manager with `daemon-reload`.
It does not restart the service. A service's `reload` operation is separate and
must be supported by that service. Apply the appropriate action, then check
status, Result/exit properties, and journal entries from the attempted run.

For oneshot services, inactive can be successful; for long-running services,
briefly becoming active is insufficient if they immediately crash. For timers
and sockets, verify both the trigger and the resulting service behavior when
safe to exercise. Check enablement separately if persistence was requested.

Report the cause supported by evidence, files changed, current state, and
whether the fix persists across login or reboot. State missing permissions or
unverified effects plainly. Include a narrow rollback path for material unit
changes rather than removing all overrides.

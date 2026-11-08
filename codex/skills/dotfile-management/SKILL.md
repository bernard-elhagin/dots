---
name: dotfile-management
description: Manage version-controlled Linux dotfiles, symlinks, backups, installation mappings, and migrations between local and tracked configuration. Use when adding configuration to a dotfiles repository, changing installation behavior, or diagnosing links and configuration ownership; not for unrelated application logic.
---

# Dotfile management

Keep the repository and installed configuration consistent while preserving
existing user data and making changes reproducible on another machine.

## Establish ownership and installation behavior

Read repository instructions and inspect `git status` before editing. Separate
existing user changes from the requested work; do not revert or stage unrelated
changes. Discover the repository rather than assuming the current directory.
This user's primary dotfiles repository is normally `~/dots`.

For each affected configuration, identify:

- The tracked source and installed destination.
- Whether the destination is a file, directory, symlink, or broken symlink.
- The resolved symlink target and whether the application writes through it.
- The installer mapping, parent-directory creation, and existing backup policy.
- Whether the file contains reusable configuration, machine-specific values,
  credentials, caches, or generated session state.

Inspect links before writing: changing a linked file changes its target.
Use `readlink` for the stored target and `readlink -f` when resolution is
appropriate; a nonexistent target needs separate handling. Test both `-e` and
`-L` when an installer must recognize broken links.

Do not infer the active configuration from the presence of similarly named
files. Check the application's launch arguments, configuration discovery, and
existing install mappings. Respect XDG or application-specific path overrides
when present; do not silently change the installer's path conventions.

## Choose the tracked source

When importing a local file, preserve its actual content and permissions where
meaningful; do not replace it with a generic template. Inspect for secrets before
copying into the repository, and keep any sensitive values out of tool output.
Track only files necessary for the requested configuration. Exclude caches,
tokens, history, databases, session snapshots, and other generated state.

Follow nearby repository organization. Here, application configuration usually
lives under `config/`, Hyprland under `hypr/`, shell files under `zsh/` or
`zprezto/runcoms/`, utilities under `bin/`, and personal Codex instructions and
skills under `codex/`. Preserve upstream plugin and submodule structure.

Link individual files when a containing directory also holds plugins, generated
state, or application-managed files. Link a whole directory only when it is
intended to be repository-owned. Do not move an entire live application state
directory into Git just to manage one setting.

## Update installation and migrate safely

Inspect `install.sh` before changing it. In `~/dots`, reuse `link_repo_path`
and `link_path`, which create parents, back up conflicting destinations with
unique timestamped names, and leave correct links alone. Add mappings to the
appropriate full-install or desktop-only path; preserve both modes' scope.

Avoid replacement commands that bypass these safeguards. Handle existing files,
directories, wrong links, and broken links deliberately. Preserve the original
until the new source and link are verified. Repeat installation should not
create additional backups for an already-correct link.

Do not run the entire installer to apply one configuration change unless that
scope is requested. If live installation is part of the task, apply the narrow
linking operation with the same backup semantics. Use required filesystem
approvals for destinations outside the workspace; repository access alone does
not authorize bypassing the environment's permission controls.

Keep machine-specific paths and output names out of reusable configuration when
practical. Preserve explicit user choices already present; do not generalize an
unrelated configuration during a focused fix. When hardware assumptions remain,
document them briefly where maintainers will find them.

## Validate the actual contract

Run syntax or application checks suited to the changed file, and
`git diff --check`. Inspect newly added files as well as tracked diffs; untracked
files are not shown by ordinary `git diff`.

For installer behavior changes, inspect all side effects before executing in a
temporary home. HOME alone does not isolate absolute paths, XDG overrides,
sudo, services, hardware commands, or network operations. Isolate or stub those
effects as needed. Verify relevant outcomes rather than installer text:

- The installed link resolves to the intended source.
- Conflicting content is preserved in the backup.
- A second installation leaves correct links and backups unchanged.
- File modes, relative paths, and directory-versus-file behavior remain correct.

Exercise edge cases proportional to the change; do not invent an installer test
framework for a simple mapping addition. For live changes, reload only the
affected application when appropriate and check its parser or focused logs.

Report the tracked source, destination, backup if created, validation, and
whether the live configuration was applied or only the installer was updated.
Do not claim an untracked file is committed, or a prepared mapping is already
installed. Leave commits and unrelated cleanup to the user's requested scope.

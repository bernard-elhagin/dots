# Repository Guidelines

## Project Structure & Module Organization

This repository manages personal Linux dotfiles and helper scripts. Top-level directories group related settings: `zsh/` and `zprezto/runcoms/` for the shell, `vim/` and `vimrc` for Vim, `tmux/` for tmux, `i3/` and `hypr/` for window managers, and `config/` for application configuration. `bin/` contains user-facing utilities; `fzf/` and `git/` hold their respective integrations. Some directories contain plugins or submodules; preserve their upstream structure when changing them.

## Build, Test, and Development Commands

There is no project-wide build or automated test suite. Changes are usually installed through symlinks into the home directory.

- `bash -n install.sh packages.sh bin/<script>.sh` checks Bash syntax without running scripts.
- `./install.sh` links settings into `$HOME`; review its targets first, especially if adapting it for another machine.
- `./packages.sh` installs the listed Arch Linux packages and clones shell and tmux plugins; run only on a compatible system when intended.

For configuration changes, validate with the relevant application (for example, start a fresh Zsh or run `tmux source-file ~/.tmux.conf`).

## Coding Style & Naming Conventions

Use Bash for shell utilities and keep scripts executable when they are intended to run directly. Follow nearby formatting: four-space indentation in shell control blocks, descriptive lower-case filenames, and uppercase names for constant-style arrays (as in `PACKAGES_TO_INSTALL`). Keep machine-specific values and generated state out of tracked files; `.gitignore` lists local caches and generated artifacts.

## Testing Guidelines

No test framework or coverage threshold is configured. For shell edits, run `bash -n` on changed scripts and exercise the relevant command in a safe environment. For dotfile edits, reload or open the target application and check for startup or parsing errors.

## Commit & Pull Request Guidelines

Recent commits use short, informal imperative summaries, sometimes with a component prefix such as `[zsh]`. Follow that pattern: keep the subject concise and name the affected configuration. Pull requests should describe the change and its effect, list any manual validation, and include screenshots only for visual changes. Call out platform assumptions, package changes, or symlink/install behavior that contributors should review.

## Security & Configuration Tips

Do not commit credentials, private keys, host-specific secrets, or generated application state. Inspect install and package scripts before running them because they change files under `$HOME` and may invoke `sudo` or clone external repositories.

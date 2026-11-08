---
name: shell-scripting
description: Create, debug, review, or refactor Bash and Zsh scripts, shell functions, startup files, and command-line utilities. Use for shell implementation and shell-specific behavior, not every task that happens to run terminal commands.
---

# Shell scripting

Preserve the command's intended behavior and interface while making its shell
semantics reliable. Prefer a focused change over rewriting a working utility.

## Establish the execution context

Read the script, its callers, and relevant repository instructions. Determine
the actual interpreter from the shebang or sourcing context; the user's
interactive shell does not determine a script's language. Keep existing Bash,
Zsh, or POSIX sh unless a change is requested or necessary.

Distinguish directly executed utilities from sourced libraries and startup
files. Sourced code must not unexpectedly exit its caller, change directory,
install traps, or alter shell options globally. Check interactive versus
noninteractive startup behavior before changing Zsh configuration.

In `~/dots`, Bash utilities generally use four-space control-block indentation;
follow nearby style and keep directly executable scripts executable. Inspect
`install.sh` when adding commands or changing their installed paths. Do not run
installers or package scripts merely to check their syntax.

## Implement with shell semantics in mind

- Pass arguments as arrays in Bash/Zsh; use `"${args[@]}"` when invoking the
  command. Quote expansions unless splitting or globbing is intentional. Avoid
  `eval` and command strings when argument passing can express the operation.
- Use `printf` for arbitrary text, `read -r` for literal input, and `--` where
  supported for filenames that may begin with a dash. Use NUL-delimited file
  traversal when arbitrary filenames are possible; do not parse `ls` output.
- Keep command status separate from declaration: `local value` followed by
  `value=$(command)` when the status matters. Account for pipeline subshells,
  lost variable updates, command substitution stripping trailing newlines,
  and producer failures hidden by process substitution.
- Choose failure handling deliberately. Do not add `set -euo pipefail` as a
  universal repair, especially to sourced code. Handle expected nonzero statuses
  such as a search with no matches. Remember `errexit` exceptions in conditions
  and functions, arithmetic commands returning false at zero, and SIGPIPE from
  intentionally shortened pipelines.
- Check empty/unset values and array behavior in the actual target shell.
  Bash and Zsh differ in array indexing, word splitting, and unmatched globs;
  do not validate Zsh-only code with Bash or assume Bash arrays are POSIX sh.
- Use structured parsers for JSON and other structured data when available.
  Preserve stdout for command results and send diagnostics to stderr. Retain
  existing exit codes, argument boundaries, and output formats used by callers.
- Use `mktemp` for temporary state and scope cleanup to resources created by
  the operation. Avoid predictable temporary names, overly broad cleanup, or
  replacing existing traps in sourced code. Use atomic replacement for state
  files when partial writes would affect readers; preserve required permissions
  and symlink semantics.
- For destructive or privileged actions, verify target paths and scope before
  execution. Respect existing authorization and use the environment's approval
  mechanism where required. Do not echo credentials, dump environments, or run
  `set -x` across secret-bearing commands.

## Validate without running the real side effects

Run the target interpreter's syntax check on changed files: `bash -n`, `zsh -n`,
or `sh -n` as appropriate. Syntax checks do not prove runtime behavior.

Use ShellCheck for supported sh/Bash code if installed. It does not support
Zsh; use Zsh's own checks and focused execution there. Inspect warnings rather
than suppressing them broadly. Use a formatter only when the project uses one
or the requested change benefits from it; avoid unrelated formatting churn.

For behavioral changes, exercise the meaningful paths in a temporary workspace.
Choose relevant cases such as missing arguments, empty results, whitespace or
leading-dash filenames, command failure, cancellation, and repeat execution.
Stub external commands when exercising them would install packages, change
system state, or contact a service. Match the real commands' exit status and
output contracts when stubbing.

For installers, a temporary home can verify symlinks, backup contents, and
idempotence, but first inspect absolute paths, XDG variables, sudo calls, and
other effects that changing HOME alone does not isolate. A sourceable startup
file may run plugins or hooks even in an otherwise fresh shell.

Use checks proportional to the change; do not create a test framework for a
small reversible edit. Finish with `git diff --check` when editing a repository,
and state what was verified and any runtime behavior that remains untested.

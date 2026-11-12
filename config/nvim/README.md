# Vim mirror in Lua

This configuration ports `~/dots/vimrc` and the active Markdown ftplugin to
Lua. Your Vim configuration itself is unchanged. Launch with `nvim`.

## Layout

- `init.lua`: module loading, Space leader and the original local leader.
- `lua/vim_mirror/options.lua`: editing options and independent persistent undo.
- `keymaps.lua`: original mappings, in their original order.
- `autocmds.lua`: filetype behavior, cursor restoration, diff and Markdown folds.
- `utils.lua`: word highlights, fold/number toggles, FZF commands.
- `theme.lua`: adventurous, red cursor, MatchParen and word-highlight colors.
- `specs.lua` / `plugins.lua`: active Vim plugin list, settings and loading.
- `codex.lua`: `:Codex`, `:CodexAsk`, `:CodexSelection`, `:CodexReview`, `gC{motion}`.

Run `:help codex` for Codex commands, selection handling, terminal controls,
and configuration. Command-specific help is available with `:help :CodexAsk`
and `:help :CodexSelection`.

The configuration is Lua; existing third-party Vim plugins and colorschemes
still use their upstream implementation language.

## Plugins and dependencies

Existing plugins under `~/.vim/plugged` are reused read-only. New installations
can run `:VimMirrorInstall` to clone missing plugins into
`~/.local/share/nvim/vim-mirror/plugins`, then restart Neovim. There are no
automatic downloads or updates during startup. Vim's own plugins are never
updated by this installer. Run `:VimMirrorHealth` for dependency status.

The system `fzf` package provides the core FZF Vim integration on Arch/CachyOS.
Other commands used by your mappings include `rg`, Git, `jq`, `xmllint`,
`column`, `toilet`, and Wayland clipboard tools. Tagbar needs Universal Ctags
(Arch package `ctags`); it was missing when this configuration was created.

UltiSnips, Gundo and MatchTagAlways need Neovim's Python provider. The portable
system dependency is `python-pynvim` (now in `packages.sh`). On this machine,
pynvim 0.6.0 was installed from the upstream `neovim/pynvim` source into a
private environment under `~/.local/share/nvim/vim-mirror/python`, using the
existing system msgpack/greenlet dependencies. Its source and license are in
the adjacent `python-src` directory. This required no root or system Python
changes. The config prefers that environment when present, otherwise uses
`/usr/bin/python3`. Without a provider, only the three Python-dependent plugins
are skipped. Your custom `~/.vim/UltiSnips` snippets are reused.

## Deliberate compatibility adjustments

- Obsolete Vim terminal/GUI options (`t_*`, `guioptions`, etc.) are omitted;
  Neovim uses `guicursor` and highlight groups instead.
- CSApprox is omitted: Neovim already supports true color.
- Polyglot's Markdown component is disabled. Markdown embedding inside Java
  Javadoc is also disabled to avoid incompatible syntax-group cleanup;
  ordinary Java and Javadoc highlighting remain available.
- Old Fugitive command names use current equivalents. Space-gl opens Git's
  last 18 commits instead of depending on an undefined `:Shell` command.
- `Ctrl-L` clears search highlighting and redraws (fixing the old `<cl>` typo).
- JSON formatting is buffer-local and uses Python 3; it no longer overwrites
  the XML formatter in unrelated buffers.
- The old Windows-only, unbound `XSLTransform()` helper is not carried over.
- After editing Lua config, restart Neovim rather than duplicating plugins
  and hooks by sourcing the entire configuration again.

The original swapped `ZZ`/`ZQ`, punctuation, Ctrl-key mappings, and duplicate
mapping precedence are preserved. Depending on the terminal, Tab/Ctrl-I and
Enter/Ctrl-M may be indistinguishable, as in Vim.

## Java language server

`packages.sh` (the default `all` or `core` profile) installs OpenJDK 25,
Node.js/npm/pnpm and download prerequisites, then runs
`bin/install_nvim_servers.sh`. This bootstraps Mason v2.3.1 when needed and
installs JDTLS and PerlNavigator into Neovim's Mason data directory. It runs
headlessly without your init.lua, so it works before `install.sh`. Existing
server executables are reused; repeated runs do not update them. Downloads need
network access and failures return a nonzero exit status. The `desktop` profile
does not install language servers. You can rerun just the server bootstrap with
`bash ~/dots/bin/install_nvim_servers.sh` after installing its dependencies.

Java files automatically start Eclipse JDTLS through Neovim's native LSP.
The config finds `jdtls` on PATH or in the existing Mason installation at
`~/.local/share/nvim/mason/bin/jdtls`. It prefers the installed OpenJDK 25
to run the server. Maven/Gradle project files determine project language levels.
Each project gets a separate cache workspace under `~/.cache/nvim/jdtls/workspaces`.
Standalone Java files also work; initial indexing can take a little time.

| Key | Action |
| --- | --- |
| `gd` / `gD` | Definition / declaration |
| `gr` / `gi` | References / implementation |
| `K` | Documentation |
| `Space cr` | Rename symbol |
| `Space ca` | Code actions |
| `Space cf` | Format |
| `Space co` | Organize imports |
| `[d` / `]d` | Previous / next diagnostic |
| `Space ce` | Show diagnostic |
| Insert `Alt-Space` | Request completion |

Completion triggers while typing identifiers and after characters such as `.`; use
`Ctrl-N`/`Ctrl-P` to select and `Ctrl-Y` to accept. `Ctrl-X Ctrl-O` also requests
completion. Run `:JavaLspInfo` to inspect the server, JDK and project workspace.

## Perl language server

PerlNavigator starts automatically for Perl files once installed. Run
`:PerlLspInstall` to install `perlnavigator-server` using pnpm into
`~/.local/share/nvim/vim-mirror/perlnavigator`, without sudo. This command needs
network access to the npm registry. A PATH or Mason installation is also detected.
Restart Neovim after installation. Use `:PerlLspInfo` for status.

Perl uses the same completion styling and shared mappings as Java: `K` for
documentation, `gd` for definitions, `gr` for references, `Space cf` for
formatting, and `[d` / `]d` for diagnostics. Availability of individual actions
depends on the server. Completion triggers while typing, including Perl sigils.
Project roots prefer `cpanfile`, `Makefile.PL`, `Build.PL`, `dist.ini`, or
`META.json`, then a Git root other than home, then the file's directory.
Optional Perl::Critic and perlimports integrations are disabled.

## Validation

With the config installed, run:

```sh
nvim --headless '+lua local ok,e=pcall(dofile,vim.fn.stdpath("config").."/tests/smoke.lua"); if not ok then print(e); vim.cmd("cquit") end' '+qa!'
```

The previous Neovim directory is preserved beside the active configuration as
`~/.config/nvim.backup-<timestamp>`. To restore it, remove the `nvim` symlink
and rename that backup directory to `nvim`.

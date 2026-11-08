-- Lua port of ~/dots/vimrc. Keep user configuration separate from plugin code.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\\\"

require("vim_mirror.options")
require("vim_mirror.plugins").setup()
require("vim_mirror.keymaps")
require("vim_mirror.autocmds")
require("vim_mirror.codex")
require("vim_mirror.theme").setup()
require("vim_mirror.lsp").setup()
require("vim_mirror.java").setup()
require("vim_mirror.perl").setup()

local function eq(expected, actual, label)
    assert(vim.deep_equal(expected, actual), label .. ": " .. vim.inspect(actual))
end
eq("adventurous", vim.g.colors_name, "theme")
eq(4, vim.o.shiftwidth, "indentation")
eq(true, vim.o.relativenumber, "relative numbers")
eq("[[[,]]]", vim.o.foldmarker, "fold markers")
eq(" ", vim.g.mapleader, "leader")
eq(2, vim.fn.exists(":Files"), "FZF loaded")
eq(2, vim.fn.exists(":Git"), "Fugitive loaded")
eq(2, vim.fn.exists(":TagbarToggle"), "Tagbar loaded")
eq(2, vim.fn.exists(":CodexSelection"), "Lua Codex commands loaded")
eq(4, vim.fn.py3eval("2+2"), "Python provider RPC")
eq(2, vim.fn.exists(":GundoToggle"), "Gundo loaded")
eq(2, vim.fn.exists(":UltiSnipsEdit"), "UltiSnips loaded")
eq(1, vim.fn.exists("*fzf#run"), "FZF core available")
eq(":", vim.fn.maparg(";", "n"), "command-line key")
eq("'", vim.fn.maparg("`", "n"), "mark navigation")
eq("<Esc>", vim.fn.maparg("jk", "i"), "insert escape")
eq("<Cmd>Git<CR>", vim.fn.maparg(" gs", "n"), "Git status")
eq("{<CR>}<Esc>O", vim.fn.maparg("{{", "i"), "brace expansion")
assert(vim.fn.maparg("gC", "n", false, true).expr == 1, "Codex operator")

local utils = require("vim_mirror.utils")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha beta alpha", "second" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
utils.highlight(1)
eq(86751, vim.fn.getmatches()[1].id, "word highlight")
eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0), "highlight preserves cursor")
vim.wo.foldlevel = 0
utils.toggle_folds()
eq(9999, vim.wo.foldlevel, "unfold")
utils.toggle_folds()
eq(0, vim.wo.foldlevel, "fold")

vim.bo.filetype = "json"
eq(1, vim.fn.maparg("=x", "n", false, true).buffer, "JSON formatter is local")
vim.cmd.enew()
assert(not vim.fn.maparg("=x", "n"):find("json.tool", 1, true), "JSON mapping must not leak")
vim.bo.filetype = "markdown"
eq("expr", vim.wo.foldmethod, "Markdown folding")
eq("v:lua.VimMirrorMarkdownFold()", vim.wo.foldexpr, "Markdown fold expression")
vim.bo.filetype = "diff"
eq("v:lua.VimMirrorDiffFold()", vim.wo.foldexpr, "diff folding")
vim.bo.filetype = "xml"
eq("syntax", vim.wo.foldmethod, "XML folding")
vim.v.errmsg = ""
vim.bo.filetype = "java"
eq("java", vim.b.current_syntax, "Java syntax loaded")
eq("", vim.v.errmsg, "Java/Markdown syntax compatibility")
eq(1, vim.g.java_ignore_markdown, "incompatible Javadoc Markdown embedding disabled")
print("PASS: theme, plugins, keymaps, word highlights, folds and filetype isolation")

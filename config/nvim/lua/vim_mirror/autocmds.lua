local group = vim.api.nvim_create_augroup("VimMirror", { clear = true })
local function autocmd(events, opts)
    opts.group = group
    vim.api.nvim_create_autocmd(events, opts)
end
vim.filetype.add({ extension = { wsdl = "xml", xslt = "xml", xsl = "xml" } })

autocmd("BufReadPost", { callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
end })
autocmd("FileType", { pattern = "xml", callback = function() vim.wo.foldmethod = "syntax" end })
_G.VimMirrorDiffFold = function()
    local line = vim.fn.getline(vim.v.lnum)
    if line:match("^diff") or line:match("^Index") then return ">1" end
    if line:match("^@@") or line:match("^%d") or
        line:match("^%*%*%* %d+,%d+ %*%*%*%*$") or line:match("^%-%-%- %d+,%d+ %-%-%-%-$") then
        return ">2"
    end
    return "="
end
autocmd("FileType", { pattern = "diff", callback = function()
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.VimMirrorDiffFold()"
end })
_G.VimMirrorMarkdownFold = function()
    local line = vim.fn.getline(vim.v.lnum)
    if line:match("^##") then return ">2" end
    if line:match("^#") then return ">1" end
    return "="
end
_G.VimMirrorMarkdownFoldText = function()
    return vim.fn.getline(vim.v.foldstart) .. " (" .. (vim.v.foldend - vim.v.foldstart) .. " lines)"
end
autocmd("FileType", { pattern = "markdown", callback = function()
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.VimMirrorMarkdownFold()"
    vim.wo.foldtext = "v:lua.VimMirrorMarkdownFoldText()"
    vim.opt_local.fillchars:append({ fold = " " })
end })
autocmd("FileType", { pattern = "json", callback = function(event)
    vim.keymap.set("n", "=x", "<Cmd>%!python3 -m json.tool<CR>", { buffer = event.buf })
end })
autocmd("BufEnter", { pattern = ".zshrc", callback = function(event)
    vim.keymap.set("n", "<Return>", "gf", { buffer = event.buf, remap = true })
end })
autocmd("CmdwinEnter", { callback = function() pcall(vim.keymap.del, "n", "<CR>", { buffer = 0 }) end })
autocmd("FileChangedShell", { callback = function() vim.cmd("echohl WarningMsg | echohl None") end })
-- Unlike a full re-source, a notification does not duplicate plugin setup.
autocmd("BufWritePost", { pattern = vim.fn.stdpath("config") .. "/*.lua", callback = function()
    vim.notify("Neovim config saved; restart Neovim to reload all modules.")
end })

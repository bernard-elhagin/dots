local M = {}
M.documentation_namespace = vim.api.nvim_create_namespace("VimMirrorDocumentation")
function M.highlights()
    vim.api.nvim_set_hl(0, "MatchParen", { fg = "red", bold = true })
    vim.api.nvim_set_hl(0, "Cursor", { fg = "black", bg = "red" })
    local popup = {
        Pmenu = { fg = "#F8F8F2", bg = "#24272D" },
        PmenuSel = { fg = "#F8F8F2", bg = "#404449", bold = true },
        PmenuKind = { fg = "#70A9E3", bg = "#24272D" },
        PmenuKindSel = { fg = "#9BC9F5", bg = "#404449" },
        PmenuExtra = { fg = "#9DA3AD", bg = "#24272D" },
        PmenuExtraSel = { fg = "#D1D5DC", bg = "#404449" },
        PmenuMatch = { fg = "#FFA724", bold = true },
        PmenuMatchSel = { fg = "#FFA724", bold = true },
        PmenuBorder = { fg = "#555B66", bg = "#24272D" },
        PmenuSbar = { bg = "#2D3138" },
        PmenuThumb = { bg = "#666E7B" },
        NormalFloat = { fg = "#F8F8F2", bg = "#24272D" },
        FloatBorder = { fg = "#555B66", bg = "#24272D" },
    }
    for group, style in pairs(popup) do vim.api.nvim_set_hl(0, group, style) end
    -- A window-local palette keeps manual-style documentation colors out of
    -- source buffers and ordinary Markdown documents.
    local docs = {
        ["@markup.heading"] = { fg = "#FFA724", bold = true },
        ["@markup.strong"] = { fg = "#70A9E3", bold = true },
        ["@markup.italic"] = { fg = "#8CFFBA", italic = true },
        ["@markup.raw"] = { fg = "#8CFFBA" },
        ["@markup.link"] = { fg = "#70A9E3", underline = true },
        ["@markup.link.url"] = { fg = "#70A9E3", underline = true },
        ["@markup.list"] = { fg = "#FFA724" },
        ["@function"] = { fg = "#70A9E3", bold = true },
        ["@keyword"] = { fg = "#FFA724", bold = true },
        ["@string"] = { fg = "#8CFFBA" },
        ["@comment"] = { fg = "#9DA3AD", italic = true },
        markdownH1 = { fg = "#FFA724", bold = true },
        markdownH2 = { fg = "#FFA724", bold = true },
        markdownBold = { fg = "#70A9E3", bold = true },
        markdownItalic = { fg = "#8CFFBA", italic = true },
        markdownCode = { fg = "#8CFFBA" },
    }
    for group, style in pairs(docs) do
        vim.api.nvim_set_hl(M.documentation_namespace, group, style)
    end
    local colors = { "#ffa724", "#aeee00", "#8cffba", "#b88853", "#ff9eb8", "#ff2c4b", "#aa2c4b", "#ffaaab" }
    for i, color in ipairs(colors) do
        vim.api.nvim_set_hl(0, "InterestingWord" .. i, { fg = "#000000", bg = color })
    end
end
function M.setup()
    vim.opt.pumborder = "rounded"
    vim.opt.winborder = "rounded"
    vim.opt.pumheight = 10
    vim.opt.pumwidth = 28
    vim.opt.pummaxwidth = 72
    vim.opt.pumblend = 0
    if not pcall(vim.cmd.colorscheme, "adventurous") then
        vim.cmd.colorscheme("default")
    end
    M.highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("VimMirrorColors", { clear = true }),
        callback = M.highlights,
    })
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("VimMirrorDocumentation", { clear = true }),
        pattern = "markdown",
        callback = function(event)
            for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
                if vim.w[win]["textDocument/hover"] then
                    vim.api.nvim_win_set_hl_ns(win, M.documentation_namespace)
                end
            end
        end,
    })
end
return M

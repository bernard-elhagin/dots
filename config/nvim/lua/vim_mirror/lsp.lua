local M = {}

function M.setup()
    local group = vim.api.nvim_create_augroup("VimMirrorLsp", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", { group = group, callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client or (client.name ~= "jdtls" and client.name ~= "perlnavigator") then return end
        local function map(mode, key, action, desc)
            vim.keymap.set(mode, key, action, { buffer = event.buf, silent = true, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "LSP: definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: declaration")
        map("n", "gr", vim.lsp.buf.references, "LSP: references")
        map("n", "gi", vim.lsp.buf.implementation, "LSP: implementation")
        map("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 20 })
        end, "LSP: documentation")
        map("n", "<leader>cr", vim.lsp.buf.rename, "LSP: rename symbol")
        map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code actions/imports")
        map({ "n", "x" }, "<leader>cf", function()
            vim.lsp.buf.format({ bufnr = event.buf, async = true, name = client.name })
        end, "LSP: format")
        if client.name == "jdtls" then
            map("n", "<leader>co", function()
                vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" }, diagnostics = {} }, apply = true })
            end, "LSP: organize imports")
        end
        map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
        map("n", "<leader>ce", vim.diagnostic.open_float, "LSP: show diagnostic")
        map("i", "<M-Space>", vim.lsp.completion.get, "LSP: completion")
        vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
        -- Native completion otherwise only opens after punctuation advertised by
        -- the server (for example '.'); also offer symbols while typing identifiers.
        local provider = client.server_capabilities.completionProvider
        if provider then
            local triggers = provider.triggerCharacters or {}
            for char in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$"):gmatch(".") do
                if not vim.tbl_contains(triggers, char) then triggers[#triggers + 1] = char end
            end
            if client.name == "perlnavigator" then
                for _, char in ipairs({ "@", "%", ":" }) do
                    if not vim.tbl_contains(triggers, char) then triggers[#triggers + 1] = char end
                end
            end
            provider.triggerCharacters = triggers
        end
        vim.lsp.completion.enable(true, client.id, event.buf, {
            autotrigger = true,
            convert = function(item)
                -- Keep the signature, but omit the repeated package/type column.
                return { abbr = item.label, menu = "" }
            end,
        })
    end })
end

return M

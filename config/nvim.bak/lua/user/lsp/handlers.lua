local M = {}

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.setup = function()
    local icons = require 'user.icons'
    local signs = {

        { name = 'DiagnosticSignError', text = icons.diagnostics.Error },
        { name = 'DiagnosticSignWarn', text = icons.diagnostics.Warning },
        { name = 'DiagnosticSignHint', text = icons.diagnostics.Hint },
        { name = 'DiagnosticSignInfo', text = icons.diagnostics.Information },
    }

    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = '' })
    end

    local config = {
        -- disable virtual text
        virtual_text = false,
        -- show signs
        signs = {
            active = signs,
        },
        update_in_insert = true,
        underline = false,
        severity_sort = true,
        float = {
            focusable = true,
            style = 'minimal',
            border = 'rounded',
            source = 'always',
            header = '',
            prefix = '',
        },
    }

    vim.diagnostic.config(config)

    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = 'rounded',
        width = 60,
    })

    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = 'rounded',
        width = 60,
    })
end

local function lsp_highlight_document(client)
    -- if client.server_capabilities.document_highlight then
    local status_ok, illuminate = pcall(require, 'illuminate')
    if not status_ok then
        return
    end
    illuminate.on_attach(client)
    -- end
end

M.on_attach = function(client, bufnr)
    -- TODO: refactor this into a method that checks if string is in list

    local status_ok, aerial = pcall(require, 'aerial')
    if not status_ok then
        return
    end
    aerial.on_attach(client, bufnr)

    if client.name == 'jdt.ls' then
        if JAVA_DAP_ACTIVE then
            require('jdtls').setup_dap { hotcodereplace = 'auto' }
            require('jdtls.dap').setup_dap_main_class_configs()
        end
        M.capabilities.textDocument.completion.completionItem.snippetSupport = false
        vim.lsp.codelens.refresh()
    else
        local status_cmp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
        if not status_cmp_ok then
            return
        end

        M.capabilities.textDocument.completion.completionItem.snippetSupport = true
        M.capabilities = cmp_nvim_lsp.update_capabilities(M.capabilities)
    end

    lsp_keymaps(bufnr)
    lsp_highlight_document(client)
end

function M.enable_format_on_save()
    vim.cmd [[
    augroup format_on_save
    autocmd!
    autocmd BufWritePre * lua vim.lsp.buf.format({ async = true })
    augroup end
    ]]
    vim.notify 'Enabled format on save'
end

function M.disable_format_on_save()
    M.remove_augroup 'format_on_save'
    vim.notify 'Disabled format on save'
end

function M.toggle_format_on_save()
    if vim.fn.exists '#format_on_save#BufWritePre' == 0 then
        M.enable_format_on_save()
    else
        M.disable_format_on_save()
    end
end

function M.remove_augroup(name)
    if vim.fn.exists('#' .. name) == 1 then
        vim.cmd('au! ' .. name)
    end
end

vim.cmd [[ command! LspToggleAutoFormat execute 'lua require('user.lsp.handlers').toggle_format_on_save()' ]]

return M

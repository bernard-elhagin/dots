local status_ok, lsp_installer = pcall(require, 'nvim-lsp-installer')
if not status_ok then
    return
end

local servers = {
    'jdtls',
    'sumneko_lua',
    'tsserver',
    'lemminx',
    'pyright',
    'perlnavigator',
    'bashls',
    'jsonls',
    'html',
    'tailwindcss',
    'arduino_language_server',
    'clangd',
}

local settings = {
    ensure_installed = servers,
    ui = {
        icons = {},
        keymaps = {
            toggle_server_expand = '<CR>',
            install_server = 'i',
            update_server = 'u',
            check_server_version = 'c',
            update_all_servers = 'U',
            check_outdated_servers = 'C',
            uninstall_server = 'X',
        },
    },

    log_level = vim.log.levels.INFO,
}

lsp_installer.setup(settings)

local lspconfig_status_ok, lspconfig = pcall(require, 'lspconfig')
if not lspconfig_status_ok then
    return
end

local opts = {}

for _, server in pairs(servers) do
    opts = {
        on_attach = require('user.lsp.handlers').on_attach,
        capabilities = require('user.lsp.handlers').capabilities,
    }

    if server == 'sumneko_lua' then
        local sumneko_opts = require 'user.lsp.settings.sumneko_lua'
        opts = vim.tbl_deep_extend('force', sumneko_opts, opts)
    end

    if server == 'perlnavigator' then
        require('user.lsp.settings.perl')
    end

    if server == 'jdtls' then
        goto continue
    end

    lspconfig[server].setup(opts)
    ::continue::
end

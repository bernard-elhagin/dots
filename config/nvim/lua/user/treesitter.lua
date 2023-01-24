local status_ok, configs = pcall(require, 'nvim-treesitter.configs')
if not status_ok then
    return
end

local ft_to_parser = require'nvim-treesitter.parsers'.filetype_to_parsername
ft_to_parser.motoko = 'typescript'

require'nvim-treesitter.configs'.setup {
}

configs.setup({
    ensure_installed = { 'html', 'java', 'json', 'bash', 'c' },
    sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
    ignore_install = { '' }, -- List of parsers to ignore installing
    highlight = {
        -- use_languagetree = true,
        enable = false, -- false will disable the whole extension
        -- disable = { 'css', 'html' }, -- list of language that will be disabled
        disable = { 'css', 'markdown' }, -- list of language that will be disabled
        -- additional_vim_regex_highlighting = true,
    },
    autopairs = {
        enable = true,
    },
    indent = { enable = true, disable = { 'python', 'css' } },
    context_commentstring = {
        enable = true,
        enable_autocmd = false,
    },
    autotag = {
        enable = true,
        filetypes = { 'xml', 'html' }
    },
    playground = {
        enable = true,
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<c-backspace>'
        }
    },
    textobjects = {
        select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ['aa'] = '@parameter.outer',
                ['ia'] = '@parameter.outer',
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
            },
        },
    },
    move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
            [']m'] = '@function.outer',
            [']]'] = '@class.outer'
        },
        goto_next_end = {
            [']M'] = '@function.outer',
            [']['] = '@class.outer'
        },
        goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[['] = '@class.outer'
        },
        goto_previous_end = {
            ['[M'] = '@function.outer',
            ['[]'] = '@class.outer'
        },
    },
    swap = {
        enable = true,
        swap_next = {
            ['<leader>a'] = '@parameter.inner'
        },
        swap_previous = {
            ['<leader>A'] = '@parameter.inner'
        },
    }
})

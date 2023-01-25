local fn = vim.fn

local home = os.getenv('HOME')
local install_path = home .. '/.local/share/nvim/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP = fn.system {
        'git',
        'clone',
        '--depth',
        '1',
        'git@github.com:wbthomason/packer.nvim',
        install_path,
    }
    print 'Installing packer...'
    vim.cmd [[packadd packer.nvim]]
end

-- Autocommand to reload neovim whenever you save plugins.lua
vim.cmd [[
    augroup packer_user_config
        autocmd!
        autocmd BufWritePost plugins.lua source <afile>
    augroup end
]]

local status_ok, packer = pcall(require, 'packer')
if not status_ok then
    return
end

packer.init {
    display = {
        open_fn = function()
            return require('packer.util').float { border = 'rounded' }
        end,
    },
}

return require('packer').startup(function()
    use 'wbthomason/packer.nvim'

    -- Color themes
    use 'rafi/awesome-vim-colorschemes'
    use 'bluz71/vim-nightfly-guicolors'
    use 'bluz71/vim-moonfly-colors'
    use 'Mofiqul/vscode.nvim'
    use 'rebelot/kanagawa.nvim'
    use 'catppuccin/nvim'
    use 'Mofiqul/dracula.nvim'
    use 'flazz/vim-colorschemes'
    use 'EdenEast/nightfox.nvim'
    use 'ofirgall/ofirkai.nvim'

    use 'nvim-lua/plenary.nvim'
    use 'kyazdani42/nvim-web-devicons'
    use 'tpope/vim-vinegar'
    use 'tpope/vim-repeat'
    use 'tpope/vim-fugitive'
    use 'romainl/vim-cool'
    use 'mhinz/vim-startify'
    use 'kevinhwang91/nvim-bqf'
    use 'Pocco81/true-zen.nvim'

    use {
        'echasnovski/mini.comment',
        config = function()
            require('mini.comment').setup({ })
        end
    }

    use {
        'kylechui/nvim-surround',
        tag = '*',
        config = function ()
            require("nvim-surround").setup({ })
        end
    }

    use {
        'windwp/nvim-autopairs',
        config = function()
            require('nvim-autopairs').setup{}
        end
    }

    use {
        'norcalli/nvim-colorizer.lua',
        event = 'BufEnter',
        config = function()
            local present, color = pcall(require, 'colorizer')
            if not present then
                return
            end

            color.setup {
                '*',
                css = { rgb_fn = true; }
            }
            vim.cmd('ColorizerAttachToBuffer')
        end
    }

    use {
        'unblevable/quick-scope',

        config = function()
            vim.g.qs_enable = 0 -- off by default
        end
    }

    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }

    -- cmp plugins
    use 'hrsh7th/nvim-cmp'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'saadparwaiz1/cmp_luasnip'
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-nvim-lua'

    -- snippets
    use 'L3MON4D3/LuaSnip'
    use 'rafamadriz/friendly-snippets'
    use 'kana/vim-textobj-user'
    use 'kana/vim-textobj-entire'

    -- Telescope
    use 'nvim-telescope/telescope.nvim'
    use 'nvim-telescope/telescope-file-browser.nvim'
    use 'tom-anders/telescope-vim-bookmarks.nvim'
    use 'nvim-telescope/telescope-media-files.nvim'
    use 'nvim-treesitter/nvim-treesitter-textobjects'

    -- Treesitter
    use 'nvim-treesitter/nvim-treesitter'
    use 'JoosepAlviste/nvim-ts-context-commentstring'
    use 'nvim-treesitter/playground'
    use 'windwp/nvim-ts-autotag'

    -- LSP
    use {
        'neovim/nvim-lspconfig',
        requires = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'folke/neodev.nvim'
        }
    }

    use 'simrat39/symbols-outline.nvim'

    use {
        'folke/trouble.nvim',
        cmd = 'TroubleToggle'
    }

    use 'mfussenegger/nvim-jdtls'

    -- Git
    use 'kdheepak/lazygit.nvim'

    use { 'phaazon/hop.nvim',

        config = function()
            require('hop').setup { keys = 'asdfjkl;weio' }

            after = {
                vim.api.nvim_set_keymap('n', 'm', "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false })<CR>",
                    { noremap = true }),
                vim.api.nvim_set_keymap('n', 'M', "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false })<CR>",
                    { noremap = true }),
            }
        end
    }

    use {
        'rest-nvim/rest.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('rest-nvim').setup({
                result_split_horizontal = false,
                result_split_in_place = false,
                skip_ssl_verification = true,
                encode_url = true,
                highlight = {
                    enabled = true,
                    timeout = 150,

                },
                result = {
                    show_url = true,
                    show_http_info = true,
                    show_headers = true,
                    formatters = {
                        json = 'jq',
                        html = function(body)
                            return vim.fn.system({'tidy', '-i', '-q', '-'}, body)
                        end
                    },
                },
                jump_to_request = false,
                env_file = '.env',
                custom_dynamic_variables = {},
                yank_dry_run = true,
            })
        end
   }

    -- [[ Highlight on yank ]]
    -- See `:help vim.highlight.on_yank()`
    local highlight_group = vim.api.nvim_create_augroup('Visual', { clear = true })
    vim.api.nvim_create_autocmd('TextYankPost', {
        callback = function()
            vim.highlight.on_yank()
        end,
        group = highlight_group,
        pattern = '*',
    })

    if PACKER_BOOTSTRAP then
        require('packer').sync()
    end
end)

local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

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

    use 'sbdchd/neoformat'
    use 'ixru/nvim-markdown'
    use 'iamcco/markdown-preview.nvim'
    use 'dhruvasagar/vim-open-url'

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

    if packer_bootstrap then
        require('packer').sync()
    end
end)

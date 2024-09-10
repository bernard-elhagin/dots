lvim.plugins = {

  { 'rest-nvim/rest.nvim' },
  { 'hrsh7th/cmp-cmdline' },
  { 'catppuccin/nvim' },
  { 'kevinhwang91/nvim-bqf' },
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
  { 'nvim-treesitter/playground' },
  { 'pineapplegiant/spaceduck' },
  { 'rafi/awesome-vim-colorschemes' },
  { 'sindrets/diffview.nvim' },
  { 'Mofiqul/dracula.nvim' },
  { 'AlexvZyl/nordic.nvim' },

  {
    'kylechui/nvim-surround',
    version = '*',
    config = function()
      require('nvim-surround').setup({})
    end
  },

  { 'smoka7/hop.nvim',

    config = function()
      require('hop').setup { keys = 'asdfjkl;weio' }

      after = {
        vim.api.nvim_set_keymap('n', 'm',
          "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false })<CR>", { noremap = true }),
        vim.api.nvim_set_keymap('n', 'M',
          "<cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false })<CR>", { noremap = true }),
      }
    end
  },

  {
      'NvChad/nvim-colorizer.lua',
      config = function()
         require('colorizer').setup({
            user_default_options = {
               names = true,
               mode = 'background',
            }
         })
      end
  },

  {
     'stevearc/oil.nvim',
     opts = {},
     dependencies = { 'nvim-tree/nvim-web-devicons' }
  },

  {
     'danielfalk/smart-open.nvim',
     branch = '0.2.x',
     config = function()
        require('telescope').load_extension('smart_open')
     end,
     dependencies = {
        { 'kkharji/sqlite.lua' },
        { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
        { 'nvim-telescope/telescope-fzy-native.nvim' },
     },
  },

  {
     'godlygeek/tabular'
  },

  {
     'DNLHC/glance.nvim'
  },

  {
     'tpope/vim-fugitive'
  },

  {
     'rbong/vim-flog'
  },

  {
     'davvid/telescope-git-grep.nvim',
     branch = 'main'
  },

  {
     'Integralist/hart-foundation',
  },

  {
     'chaoren/vim-wordmotion',
  },

  {
     'rose-pine/neovim',
     name = 'rose-pine'
  },

  {
     'junegunn/fzf.vim',
  },

  {
     'Matsuuu/pinkmare',
  },

  {
     'folke/tokyonight.nvim',
  },

  {
     'debugloop/telescope-undo.nvim',
     dependencies = {
        {
           'nvim-telescope/telescope.nvim',
           dependencies = { 'nvim-lua/plenary.nvim' },
        },
     },
     keys = {
        {
           '<leader>u',
           '<cmd>Telescope undo<cr>',
           desc = 'Undo history',
        },
     },
     opts = {
        extensions = {
           undo = {

           },
        },
     },
     config = function(_, opts)
        require('telescope').setup(opts)
        require('telescope').load_extension('undo')
     end,
  },

  {
     'mattn/emmet-vim',
  },

  {
     'ziontee113/color-picker.nvim',
     config = function ()
        require('color-picker')
     end
  },

  {
     'AndrewRadev/tagalong.vim',
  },

  {
     'scottmckendry/cyberdream.nvim',
     lazy = false,
     priority = 1000,
     config = function()
        require('cyberdream').setup({
           transparent = true,
           italic_comments = true,
           hide_fillchars = true,
           borderless_telescope = true,
           terminal_colors = true,
        })
        vim.cmd('colorscheme cyberdream')
     end,
  },

  {
     'tpope/vim-dadbod',
     'kristijanhusak/vim-dadbod-completion',
     'kristijanhusak/vim-dadbod-ui'
  },

}

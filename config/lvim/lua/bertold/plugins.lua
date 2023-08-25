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

  { 'phaazon/hop.nvim',

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

}

lvim.plugins = {

  { 'rest-nvim/rest.nvim' },
  { 'hrsh7th/cmp-cmdline' },
  { 'catppuccin/nvim' },
  { 'kevinhwang91/nvim-bqf' },
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
  { 'tamago324/lir-bookmark.nvim' },
  { 'pineapplegiant/spaceduck' },
  { 'rafi/awesome-vim-colorschemes' },
  { 'sindrets/diffview.nvim' },

  {
    'kylechui/nvim-surround',
    tag = '*',
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

}

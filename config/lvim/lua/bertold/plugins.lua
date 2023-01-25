lvim.plugins = {
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
    'catppuccin/nvim'
  },

  {
    'kevinhwang91/nvim-bqf'
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
    'rest-nvim/rest.nvim'
  },

  {
    'hrsh7th/cmp-cmdline'
  },

}

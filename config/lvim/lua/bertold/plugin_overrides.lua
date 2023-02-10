local components = require "lvim.core.lualine.components"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "startify"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.illuminate.active = false
lvim.builtin.autopairs.active = false
lvim.builtin.indentlines.active = false
lvim.builtin.nvimtree.active = false
lvim.builtin.bufferline.active = false
lvim.builtin.project.active = false
lvim.builtin.cmp.cmdline.enable = true
lvim.builtin.cmp.cmdline.options = {
   {
      type = ":",
      sources = {
         { name = "cmdline" },
         { name = "path" },
      },
   },
   {
      type = { "/", "?" },
      sources = {
         { name = "buffer" },
      },
   },
}

lvim.builtin.alpha.startify.section.header.val = {
   [[  _  _  ____   ]],
   [[ | || ||___ \  ]],
   [[ | || |_ __) | ]],
   [[ |__   _/ __/  ]],
   [[    |_||_____| ]],
}

lvim.builtin.lualine.sections.lualine_c = {
   components.scrollbar,
   components.filename
}

lvim.builtin.treesitter.ensure_installed = {
   "bash",
   "c",
   "javascript",
   "json",
   "lua",
   "python",
   "typescript",
   "tsx",
   "css",
   "rust",
   "java",
   "yaml",
   "http",
}

lvim.builtin.treesitter.highlight.enable = true
lvim.builtin.treesitter.indent.enable = false

lvim.builtin.which_key.mappings.c = lvim.builtin.which_key.mappings.s
lvim.builtin.which_key.mappings.d = { }
lvim.builtin.which_key.mappings.s = { }
lvim.builtin.which_key.mappings.b = { }

lvim.builtin.treesitter.textobjects.select = {
   enable = true,
   keymaps = {
      ['af'] = '@function.outer',
      ['if'] = '@function.inner',
      ['ac'] = '@class.outer',
      ['ic'] = '@class.inner',
   }
}

local actions = require'lir.actions'

lvim.builtin.lir = vim.tbl_extend("force", lvim.builtin.lir, {
   show_hidden_files = true,
   devicons_enable = true,
   mappings = {
      ['l']     = actions.edit,
      ['<C-s>'] = actions.split,
      ['<C-v>'] = actions.vsplit,
      ['<C-t>'] = actions.tabedit,

      ['h']     = actions.up,
      ['q']     = actions.quit,

      ['K']     = actions.mkdir,
      ['N']     = actions.newfile,
      ['R']     = actions.rename,
      ['@']     = actions.cd,
      ['Y']     = actions.yank_path,
      ['.']     = actions.toggle_show_hidden,

      ['B']     = require'lir.bookmark.actions'.list,
      ['ba']    = require'lir.bookmark.actions'.add,
   }
})

local b_actions = require'lir.bookmark.actions'
require'lir.bookmark'.setup {
   bookmark_path = '~/.lir_bookmarks',
   mappings = {
      ['l']     = b_actions.edit,
      ['<C-s>'] = b_actions.split,
      ['<C-v>'] = b_actions.vsplit,
      ['<C-t>'] = b_actions.tabedit,
      ['<C-e>'] = b_actions.open_lir,
      ['B']     = b_actions.open_lir,
      ['q']     = b_actions.open_lir,
   }
}

local components = require "lvim.core.lualine.components"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "startify"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true
lvim.builtin.illuminate.active = false
lvim.builtin.autopairs.active = false
lvim.builtin.indentlines.active = false
lvim.builtin.nvimtree.active = true
lvim.builtin.bufferline.active = false
lvim.builtin.project.active = false
lvim.builtin.lir.active = false
lvim.builtin.gitsigns.active = true
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

lvim.builtin.lualine.options = {
   theme = 'dracula-nvim'
}

lvim.builtin.treesitter.ensure_installed = {
   "bash",
   "c",
   "css",
   "http",
   "java",
   "javascript",
   "json",
   "lua",
   "python",
   "rust",
   "tsx",
   "typescript",
   "yaml",
}

lvim.builtin.treesitter.highlight.enable = true
lvim.builtin.treesitter.indent.enable = false

lvim.builtin.which_key.mappings.c = lvim.builtin.which_key.mappings.s
lvim.builtin.which_key.mappings.g.g = { }
lvim.builtin.which_key.mappings.d = { }
lvim.builtin.which_key.mappings.s = { }
lvim.builtin.which_key.mappings.b = { }
lvim.builtin.which_key.mappings.w = { }

lvim.builtin.treesitter.textobjects.select = {
   enable = true,
   keymaps = {
      ['af'] = '@function.outer',
      ['if'] = '@function.inner',
      ['ac'] = '@class.outer',
      ['ic'] = '@class.inner',
      ['ai'] = '@conditional.outer',
      ['ii'] = '@conditional.inner',
      ['al'] = '@loop.outer',
      ['il'] = '@loop.inner',
      ['aa'] = '@attribute.outer',
      ['ia'] = '@attribute.inner',
   }
}

lvim.builtin.treesitter.textobjects.move = {
   enable = true,
   set_jumps = true,
   goto_next_start = {
      [']f'] = '@function.outer',
   },
   goto_previous_start = {
      ['[f'] = '@function.outer',
   },
   goto_next_end = {
      [']F'] = '@function.outer',
   },
   goto_previous_end = {
      ['[F'] = '@function.outer',
   }
}

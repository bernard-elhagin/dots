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
lvim.builtin.lir.show_hidden_files = true
lvim.builtin.project.active = false

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

local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
  i = {
    ['<C-c>'] = actions.close,
    ['<esc>'] = actions.close,
    ['jk'] = actions.close,
  }
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

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true
lvim.builtin.treesitter.indent.enable = false
lvim.builtin.treesitter.textobjects.select = {
  enable = true,
  lookahead = true,

  keymaps = {
    ['af'] = '@function.outer',
    ['if'] = '@function.inner',
    ['ac'] = '@class.outer',
    ['ic'] = '@class.inner',
  }
}

lvim.builtin.which_key.mappings.c = lvim.builtin.which_key.mappings.s
lvim.builtin.which_key.mappings.d = { }
lvim.builtin.which_key.mappings.s = { }
lvim.builtin.which_key.mappings.b = { }

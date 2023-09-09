vim.opt.autochdir = true
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.backspace = { 'indent', 'eol', 'start' }
vim.opt.backup = false
vim.opt.clipboard = 'unnamed'
vim.opt.cmdheight = 1
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.cursorline = false
vim.opt.diffopt = { 'internal', 'filler', 'context:3', 'indent-heuristic', 'algorithm:patience' }
vim.opt.encoding = 'utf-8'
vim.opt.errorbells = false
vim.opt.expandtab = true
vim.opt.fileformats = { 'unix', 'dos' }
vim.opt.fillchars:append('fold:•')
vim.opt.fillchars:append('vert:┃')
vim.opt.fillchars = 'diff:∙'
vim.opt.foldcolumn = '0'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldlevelstart = 666
vim.opt.foldmarker = '[[[,]]]'
vim.opt.foldmethod = 'marker'
vim.opt.gdefault = true
vim.opt.hidden = true
vim.opt.history = 5000
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.lazyredraw = true
vim.opt.magic = true
vim.opt.mouse = ''
vim.opt.number = true
vim.opt.path = { '.', '/usr/include', '~/Devel/Projects/**' }
vim.opt.pumheight = 12
vim.opt.relativenumber = true
vim.opt.ruler = true
vim.opt.scrolloff = 4
vim.opt.shiftwidth = 3
vim.opt.showmatch = true
vim.opt.showmode = false
vim.opt.showtabline = 0
vim.opt.signcolumn = 'yes'
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.startofline = true
vim.opt.suffixesadd = { '.lua', '.xml' }
vim.opt.swapfile = false
vim.opt.synmaxcol = 200
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.timeoutlen = 1000
vim.opt.updatetime = 1000
vim.opt.visualbell = false
vim.opt.whichwrap = '<,>,[,]'
vim.opt.wildmenu = true
vim.opt.wildmode = 'full'
vim.opt.wildoptions = { 'pum', 'tagfile' }
vim.opt.wrap = false

vim.opt.list = true
vim.opt.listchars = 'nbsp:⦸'
vim.opt.listchars:append('tab:▷-')
vim.opt.listchars:append('extends:»')
vim.opt.listchars:append('precedes:«')
vim.opt.listchars:append('trail:•')

vim.opt.wildignore = { '*\\tmp\\*', '*.sw?', '*.zip', '*.settings', '*.esb_diagram', '*\\*sandbox\\*', '*.classpath', '*\\.meta\\*', '.git', '*.orig', '*.exe', '*.o', '*.obj', '*.dll', '*.manifest', '*.jpg', '*.jpeg', '*.bmp', '*.gif', '*.png' }

vim.cmd [[
  autocmd BufReadPost *  if line("'\"") > 1 && line("'\"") <= line("$")
                     \|     exe "normal! g`\""
                     \|  endif

]]

vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = vim.api.nvim_create_augroup("cmd-line-relnum-toggle", { clear = false }),
  callback = function ()
    vim.wo.relativenumber = not vim.wo.relativenumber
    vim.cmd [[ redraw ]]
  end
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = vim.api.nvim_create_augroup("cmd-line-relnum-toggle", { clear = false }),
  callback = function ()
    vim.wo.relativenumber = not vim.wo.relativenumber
    vim.cmd [[ redraw ]]
  end
})

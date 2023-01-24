local o = vim.opt

o.history = 5000
o.encoding = 'utf-8'
o.showmode = false
o.scrolloff = 4
o.wildmenu = true
o.wildmode = 'full'
o.wildoptions = { 'pum', 'tagfile' }
o.ruler = true
o.cmdheight = 1
o.backspace = { 'indent', 'eol', 'start' }
o.incsearch = true
o.magic = true
o.showmatch = true
o.errorbells = false
o.visualbell = false
o.lazyredraw = true
o.ignorecase = true
o.hlsearch = true
o.smartcase = true
o.number = true
o.relativenumber = true
o.gdefault = true
o.backup = false
o.swapfile = false
o.autoread = true
o.fileformats = { 'unix', 'dos' }
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smarttab = true
o.autoindent = true
o.smartindent = true
o.wrap = false
o.laststatus = 2
o.path = { '.', '/usr/include', '~/Devel/Projects/**' }
o.suffixesadd = { '.lua', '.xml' }
o.autochdir = true
o.synmaxcol = 200
o.diffopt = { 'internal', 'filler', 'context:3', 'indent-heuristic', 'algorithm:patience' }
o.clipboard = 'unnamed'
o.hidden = true
o.updatetime = 1000
o.timeoutlen = 1000
o.splitbelow = true
o.splitright = true
o.pumheight = 12
o.termguicolors = true
o.completeopt = { 'menu', 'menuone', 'noselect' }
o.foldmethod = 'expr'
o.foldexpr = 'nvim_treesitter#foldexpr()'
o.foldlevelstart = 666
o.foldcolumn = '0'
o.startofline = true
o.signcolumn = 'yes'

o.fillchars = 'diff:∙'              -- BULLET OPERATOR (U+2219, UTF-8: E2 88 99)
o.fillchars:append('fold:•')        -- MIDDLE DOT (U+00B7, UTF-8: C2 B7)
o.fillchars:append('vert:┃')        -- BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)

o.list = true
o.listchars = 'nbsp:⦸'              -- CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
o.listchars:append('tab:▷-')        -- WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7) + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
o.listchars:append('extends:»')     -- RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
o.listchars:append('precedes:«')    -- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
o.listchars:append('trail:•')       -- BULLET (U+2022, UTF-8: E2 80 A2)

o.wildignore = { '*\\tmp\\*', '*.sw?', '*.zip', '*.settings', '*.esb_diagram', '*\\*sandbox\\*', '*.classpath', '*\\.meta\\*', '.git', '*.orig', '*.exe', '*.o', '*.obj', '*.dll', '*.manifest', '*.jpg', '*.jpeg', '*.bmp', '*.gif', '*.png' }

vim.cmd [[
  if !isdirectory('~/tmp/.NVIM_UNDO_FILES')
      call mkdir('~/tmp/.NVIM_UNDO_FILES', "p")
  endif

  set undodir=~/tmp/.NVIM_UNDO_FILES
  set undolevels=5000
  set undofile

  " Goto last location in non-empty files
  autocmd BufReadPost *  if line("'\"") > 1 && line("'\"") <= line("$")
                     \|     exe "normal! g`\""
                     \|  endif

  autocmd! BufWritePost $MYVIMRC source $MYVIMRC | echom "Reloaded $MYVIMRC"

  syntax enable
  " Change cursor shape/color depending on mode
  if &term =~ "xterm\\|rxvt"
    " use an orange cursor in insert mode
    let &t_SI = "\<Esc>]12;red\x7"
    " use a red cursor otherwise
    let &t_EI = "\<Esc>]12;red\x7"
    silent !echo -ne "\033]12;red\007"
    " reset cursor when vim exits
    autocmd VimLeave * silent !echo -ne "\033]112\007"
    " use \003]12;gray\007 for gnome-terminal and rxvt up to version 9.21
  endif

  if &term =~ "xterm\\|rxvt"
    " solid underscore
    let &t_SI .= "\<Esc>[5 q"
    " solid block
    let &t_EI .= "\<Esc>[1 q"
    " 1 or 0 -> blinking block
    " 3 -> blinking underscore
    " Recent versions of xterm (282 or above) also support
    " 5 -> blinking vertical bar
    " 6 -> solid vertical bar
  endif
]]

local opt = vim.opt
local values = {
    history = 3000, showmode = false, scrolloff = 4, ruler = true,
    cmdheight = 2, backspace = { "indent", "eol", "start" },
    incsearch = true, magic = true, showmatch = true,
    errorbells = false, visualbell = false, lazyredraw = true,
    ignorecase = true, hlsearch = true, smartcase = true,
    number = true, relativenumber = true, gdefault = true,
    backup = false, swapfile = false, autoread = true,
    fileformats = { "unix", "dos" }, expandtab = true,
    shiftwidth = 4, shiftround = true, tabstop = 4, smarttab = true,
    autoindent = true, smartindent = true, copyindent = true,
    wrap = false, laststatus = 2, synmaxcol = 200, foldcolumn = "0",
    diffopt = { "internal", "filler", "context:3", "indent-heuristic", "algorithm:patience" },
    clipboard = { "unnamed", "unnamedplus" }, hidden = true,
    updatetime = 1000, timeoutlen = 150, splitbelow = true, splitright = true,
    wildmode = { "list:longest", "full" }, wildoptions = { "pum", "fuzzy" },
    wildignorecase = true, wildmenu = true, list = true,
    fillchars = { diff = "∙", fold = "·", vert = "┃" },
    listchars = { nbsp = "⦸", tab = "▷-", extends = "»", precedes = "«", trail = "•" },
    termguicolors = true, undolevels = 5000, undofile = true,
    foldlevelstart = 9999, foldmethod = "marker", foldmarker = "[[[,]]]",
    background = "dark", mouse = "", -- Match Vim rather than Neovim defaults.
}
for name, value in pairs(values) do opt[name] = value end
opt.path:append({ ".", vim.fn.expand("~/Devel/Projects/**") })
opt.suffixesadd:append(".xml")
opt.wildignore:append({
    [[*\tmp\*]], "*.sw?", "*.zip", "*.settings", "*.esb_diagram",
    [[*\*sandbox\*]], "*.classpath", [[*\.meta\*]], ".git", "*.orig",
    "*.exe", "*.o", "*.obj", "*.dll", "*.manifest",
    "*.jpg", "*.jpeg", "*.bmp", "*.gif", "*.png",
})
-- Keep Neovim's undo files separate from Vim's.
local undo = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undo, "p", 448)
opt.undodir = undo
opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor,o:hor50-Cursor"

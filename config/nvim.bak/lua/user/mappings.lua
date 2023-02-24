local noresi = { noremap = true, silent = true }

local function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

map('i', 'jk', '<ESC>', { noremap = false })
map('v', '<c-j><c-k>', '<ESC>')
map('c', 'jk', '<C-U> <ESC>')

map('n', ';', ':')
map('v', ';', ':')
map('n', ':', ';')

map('n', '<leader>s', ':w<CR>')

map('n', '<leader>v',  ':tabedit $MYVIMRC<CR>')
map('n', '<leader>V',  ':so $MYVIMRC<CR>')

-- paste the contents of the clipboard
map('n', '<C-Space>', '"*p')
-- copy whole buffer to clipboard and quit
map('n', '<M-Space>', 'gg"*yG:q!<CR>')

-- run previous shell command
map('n', '<leader>r', ':!<UP><CR>')
map('n', '<leader>p', ':set paste!<CR>')

map('n', '<leader>j', '<C-w>j')
map('n', '<leader>k', '<C-w>k')
map('n', '<leader>l', '<C-w>l')
map('n', '<leader>h', '<C-w>h')
map('n', '<leader>x', '<C-w>c')
map('n', '<leader>o', '<C-w>o')
map('n', '<leader>_', '<C-w>_')

map('n', '<leader>q', ':QuickScopeToggle<CR>')

map('n', '<F12>', ':cd %:h<CR>')

map('n', '<F7>', ':tabprev<CR>')

map('n', '<leader>z', 'za')
map('v', '<leader>z', 'za')

map('n', 'H', '^')
map('v', 'H', '^')
map('n', 'L', 'g_')
map('v', 'L', 'g_')

map('i', '{{', '{' .. '<enter>' .. '}<ESC>O')
map('i', ',,', ',<CR>')

map('n', 'ZZ', 'ZQ')
map('n', 'ZQ', 'ZZ')

map('n', 'Q', '<nop>')

-- command mode move to end and home like in shell
map('c', '<C-a>', '<Home>')
map('c', '<C-e>', '<End>')

map('n', 'Y', 'y$')

-- quickly move around in insert mode
map('i', '<c-l>', '<right>')
map('i', '<c-h>', '<left>')
map('i', '<c-j>', '<ESC>A')
map('i', '<c-o>', '<ESC>I')

-- edit file even if it doesn't exist
map('n', 'gf', ':edit <cfile><cr>')

map('n', '<leader>os', ':edit ~/.config/nvim/lua/user/settings.lua<CR>')
map('n', '<leader>of', ':edit ~/.config/nvim/lua/user/filetypes.lua<CR>')
map('n', '<leader>om', ':edit ~/.config/nvim/lua/user/mappings.lua<CR>')
map('n', '<leader>op', ':edit ~/.config/nvim/lua/user/plugins.lua<CR>')
map('n', '<leader>ot', ':edit ~/.config/nvim/lua/user/theme.lua<CR>')

-- create text-object between / /
map('o', 'i/', ':<C-U>normal! T/vt/<CR>', noresi)
map('o', 'a/', ':<C-U>normal! F/vf/<CR>', noresi)
map('x', 'i/', ':<C-U>normal! T/vt/<CR>', noresi)
map('x', 'a/', ':<C-U>normal! F/vf/<CR>', noresi)

-- create text-object between | |
map('o', 'i|', ':<C-U>normal! T|vt|<CR>', noresi)
map('o', 'a|', ':<C-U>normal! F|vf|<CR>', noresi)
map('x', 'i|', ':<C-U>normal! T|vt|<CR>', noresi)
map('x', 'a|', ':<C-U>normal! F|vf|<CR>', noresi)

-- remove trailing whitespace
map('n', '<leader>w',":%s/\\s\\+$//<CR>")

map('n', '<F10>', ':TSHighlightCapturesUnderCursor<CR>')

-- copy-paste whole paragraph
map('n', '<C-p>', "yap'[V']y']p")

-- Ctrl-]
map('n', '<c-u>', '')

-- Packer
map('n', '<leader>pc', ':PackerCompile<CR>', { noremap = true })
map('n', '<leader>pi', ':PackerInstall<CR>', { noremap = true })
map('n', '<leader>ps', ':PackerSync<CR>',    { noremap = true })

-- Telescope
map('n', '<c-g>', ':Telescope git_files<CR>')
map('n', '<leader>ya', ':Telescope live_grep<CR>')
map('n', '<leader>ym', ':Telescope man_pages<CR>')
map('n', '<leader>yc', ':Telescope colorscheme<CR>')
map('n', '<leader>yb', ':Telescope git_branches<CR>')
map('n', '<leader>yh', ':Telescope command_history<CR>')
map('n', '<leader>yr', ':Telescope registers<CR>')
map('n', '<leader>yd', ':Telescope diagnostics<CR>')
map('n', '<leader>b',  ':Telescope buffers<CR>')
map('n', '<c-h>',      ':Telescope help_tags<CR>')
map('n', '<leader>ff', ":lua require('telescope.builtin').find_files(require('telescope').setup{ defaults = { layout_strategy = 'vertical', layout_config = { height = 0.90, preview_height = 0 } } })<CR>")

vim.keymap.set('n', '<leader><leader>', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader>b', require('telescope.builtin').buffers, { desc = '[B] Find existing buffers' })
vim.keymap.set('n', '<leader>/', require('telescope.builtin').current_buffer_fuzzy_find, { desc = '[/] Fuzzy search current buffer' })

-- Lsp
map('n', 'gD', ':lua vim.lsp.buf.declaration()<CR>',                         noresi)
map('n', 'gd', ':lua vim.lsp.buf.definition()<CR>',                          noresi)
map('n', 'K',  ':lua vim.lsp.buf.hover()<CR>',                               noresi)
map('n', 'gI', ':lua vim.lsp.buf.implementation()<CR>',                      noresi)
map('n', '<leader>D', ':lua vim.lsp.buf.type_definition()<CR>',              noresi)
map('n', '<leader>rn', ':lua vim.lsp.buf.rename()<CR>',                      noresi)
map('n', '<leader>ca', ':lua vim.lsp.buf.code_action()<CR>',                 noresi)
map('n', 'gr', ':lua vim.lsp.buf.references()<CR>',                          noresi)
map('n', '[d', ':lua vim.lsp.diagnostic.goto_prev()<CR>',                    noresi)
map('n', ']d', ':lua vim.lsp.diagnostic.goto_next()<CR>',                    noresi)
map('n', '<leader>e', ':lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', noresi)

-- XML formatting
map('n', '=x', ':exe ":silent %!xmllint --format --recover - 2>/dev/null"<CR>:set filetype=xml<CR>', noresi)

-- Stardict
-- TODO: Change this to LUA
vim.cmd [[
function! ScratchBuffer()
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
endfu

nnoremap <leader>d :new \| read ! sdcv <c-r><c-w> <cr>:call ScratchBuffer() <cr>:normal gg<cr>
]]

-- Misc
-- create empty line below or above in Normal mode
map('n', 'go', 'o<ESC>k^', noresi)
map('n', 'gO', 'O<ESC>j^', noresi)

map('n', '<up>', '<c-^>', noresi)

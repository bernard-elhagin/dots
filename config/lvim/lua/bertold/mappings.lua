vim.g.mapleader = ' '

local nore = { noremap = true }

vim.keymap.set('n', '<leader>s', ':w<cr>', nore)
vim.keymap.set('i', 'jk', '<ESC>', nore)
vim.keymap.set('c', 'jk', '<c-u><ESC>', nore)
vim.keymap.set('v', '<c-j><c-k>', '<ESC>', nore)
vim.keymap.set('n', ';', ':', nore)
vim.keymap.set('v', ';', ':', nore)
vim.keymap.set('n', ':', ';', nore)
vim.keymap.set('n', 'H', '^',  nore)
vim.keymap.set('n', 'L', 'g_', nore)
vim.keymap.set('i', '{{', '{' .. '<enter>' .. '}<esc>O', nore)
vim.keymap.set('n', '-', ":lua require'lir.float'.toggle()<CR>", nore)
vim.keymap.set('n', '<leader>v', ':e $HOME/.config/lvim/config.lua<cr>', nore)
vim.keymap.set('n', '<leader>z', 'za', nore)
vim.keymap.set('n', '<c-t>', ':ToggleTerm<cr>', nore)
vim.keymap.set('n', '<c-h>', ':Telescope help_tags<cr>', nore)
vim.keymap.set('n', '<leader>b', ':Telescope buffers<cr>', nore)
vim.keymap.set('n', '<c-p>', "yap']p", nore)
vim.keymap.set('n', 'ZZ', 'ZQ', nore)
vim.keymap.set('n', 'ZQ', 'ZZ', nore)
vim.keymap.set('c', '<c-a>', '<Home>', nore)
vim.keymap.set('i', '<c-l>', '<right>', nore)
vim.keymap.set('i', '<c-h>', '<left>', nore)
vim.keymap.set('i', '<c-j>', '<esc>A', nore)
vim.keymap.set('i', '<c-o>', '<esc>I', nore)
vim.keymap.set('n', '<up>', '<c-^>', nore)

-- Map dot to repeat last edit over entire visual selection
vim.keymap.set('v', '.', ':normal .<CR>', nore)

vim.keymap.set('n', '<leader>j', '<C-w>j', nore)
vim.keymap.set('n', '<leader>k', '<C-w>k', nore)
vim.keymap.set('n', '<leader>l', '<C-w>l', nore)
vim.keymap.set('n', '<leader>h', '<C-w>h', nore)
vim.keymap.set('n', '<leader>x', '<C-w>c', nore)
vim.keymap.set('n', '<leader>o', '<C-w>o', nore)
vim.keymap.set('n', '<leader>_', '<C-w>_', nore)

vim.keymap.set('n', '=x', ':exe ":silent %!xmllint --format --recover - 2>/dev/null"<cr>:set filetype=xml<cr>', nore)

vim.cmd [[
function! ScratchBuffer()
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
endfu

nnoremap <leader>d :new \| read ! sdcv <c-r><c-w> <cr>:call ScratchBuffer() <cr>:normal gg<cr>
]]

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern='*',
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg="grey8" })
  end,
})

function ToggleFold()
  if vim.wo.foldlevel == 0 then
    vim.opt.foldlevel = 666
  else
    vim.opt.foldlevel = 0
  end
end

vim.keymap.set('n', '<leader>e', ":lua ToggleFold()<cr>", nore)

function ToggleNumbers()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = not vim.wo.relativenumber
end

vim.keymap.set('n', '<leader>n', ":lua ToggleNumbers()<cr>", nore)

function ToggleHighlight()
  vim.go.hlsearch = not vim.go.hlsearch
end

vim.keymap.set('n', '<backspace>', ':lua ToggleHighlight()<cr>', nore)

vim.keymap.set('n', '<leader><leader>d', function()
   if next(require('diffview.lib').views) == nil then
      vim.cmd('DiffviewOpen')
   else
      vim.cmd('DiffviewClose')
   end
end)

function basic_text_objects()
   local chars = { '_', '.', ':', ',', ';', '|', '/', '\\', '*', '+', '%', '`', '?' }
   for _,char in ipairs(chars) do
      for _,mode in ipairs({ 'x', 'o' }) do
         vim.api.nvim_set_keymap(mode, 'i' .. char, string.format(':<c-u>normal! T%svt%s<cr>', char, char, char), { noremap = true, silent = true })
         vim.api.nvim_set_keymap(mode, 'a' .. char, string.format(':<c-u>normal! F%svf%s<cr>', char, char, char), { noremap = true, silent = true })
      end
   end
end

return {
   basic_text_objects = basic_text_objects
}

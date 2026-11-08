local M = {}
function M.toggle_folds()
    vim.wo.foldlevel = vim.wo.foldlevel == 0 and 9999 or 0
end
function M.toggle_numbers()
    vim.wo.number = not vim.wo.number
    vim.wo.relativenumber = not vim.wo.relativenumber
end
function M.highlight(number)
    local word = vim.fn.expand("<cword>")
    if word == "" then return end
    local id = 86750 + number
    pcall(vim.fn.matchdelete, id)
    local pattern = [[\V\<]] .. vim.fn.escape(word, [[\]]) .. [[\>]]
    vim.fn.matchadd("InterestingWord" .. number, pattern, 1, id)
end
function M.inspect_highlight()
    local line, col = vim.fn.line("."), vim.fn.col(".")
    local id = vim.fn.synID(line, col, 1)
    local translated = vim.fn.synIDtrans(id)
    vim.notify("hi<" .. vim.fn.synIDattr(id, "name") .. "> trans<" ..
        vim.fn.synIDattr(vim.fn.synID(line, col, 0), "name") .. "> lo<" ..
        vim.fn.synIDattr(translated, "name") .. "> FG:" .. vim.fn.synIDattr(translated, "fg#"))
end
function M.file_directory()
    local file = vim.api.nvim_buf_get_name(0)
    if file ~= "" then vim.api.nvim_set_current_dir(vim.fs.dirname(file)) end
end
function M.run_file()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then return end
    vim.cmd("!clear && " .. vim.fn.shellescape(file))
end

function M.find_in_repo()
    vim.fn["fzf#run"](vim.fn["fzf#wrap"]({ source = "git ls-files", sink = "e" }))
end
vim.api.nvim_create_user_command("FindInRepo", M.find_in_repo, { nargs = "*", bang = true })
vim.api.nvim_create_user_command("Find", function(args)
    local command = "rg --column --line-number --no-heading --fixed-strings --ignore-case " ..
        "--no-ignore --hidden --follow --glob '!.git/*' --color always " .. vim.fn.shellescape(args.args)
    vim.fn["fzf#vim#grep"](command, 1, args.bang and 1 or 0)
end, { nargs = "*", bang = true })
return M

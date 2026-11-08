local M = { missing = {} }
local specs = require("vim_mirror.specs").specs
local install_root = vim.fn.stdpath("data") .. "/vim-mirror/plugins"

function M.setup()
    -- Java's bundled Javadoc parser includes the bundled Markdown syntax and
    -- expects its group names. Polyglot's Markdown replacement is incompatible.
    vim.g.polyglot_disabled = { "markdown" }
    -- Java's Markdown syntax include can still resolve to Polyglot's disabled
    -- stub depending on runtime order. Avoid its incompatible group cleanup.
    vim.g.java_ignore_markdown = 1
    local private_python = vim.fn.stdpath("data") .. "/vim-mirror/python/bin/python"
    vim.g.python3_host_prog = vim.fn.executable(private_python) == 1 and private_python or "/usr/bin/python3"
    vim.fn.system({ vim.g.python3_host_prog, "-c", "import pynvim" })
    M.python_available = vim.v.shell_error == 0
    if not M.python_available then
        vim.g.loaded_python3_provider = 0
    end
    vim.g.UltiSnipsExpandTrigger = "<tab>"
    vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
    vim.g.UltiSnipsListSnippets = "<c-t>"
    vim.g.UltiSnipsJumpBackwardTrigger = "<c-z>"
    vim.g.UltiSnipsSnippetDirectories = { "UltiSnips" }
    vim.g.airline_powerline_fonts = 1
    vim.g.airline_theme = "papercolor"
    vim.g.qs_enable = 0
    vim.g.startify_custom_header = ""
    vim.g.startify_change_to_vcs_root = 1
    vim.g.xml_syntax_folding = 1
    vim.g.gitgutter_map_keys = 0
    vim.g.session_autosave = "no"
    vim.g.session_autoload = "no"
    vim.g.arduino_cmd = vim.fn.expand("~/bin/arduino-1.8.15/arduino")
    vim.g.arduino_dir = vim.fn.expand("~/bin/arduino-1.8.15")
    vim.g.arduino_home_dir = vim.fn.expand("~/.arduino15")
    vim.g.arduino_args = "--verbose-upload"

    for _, spec in ipairs(specs) do
        local path = install_root .. "/" .. spec.name
        if vim.fn.isdirectory(path) == 0 then
            path = vim.fn.expand("~/.vim/plugged/") .. spec.name
        end
        if vim.fn.isdirectory(path) == 1 then
            -- Reuse existing Vim plugins without editing or updating them.
            -- CSApprox is a Vim GUI compatibility shim, unnecessary in Neovim.
            if spec.name ~= "CSApprox" and
                (M.python_available or (spec.name ~= "ultisnips" and spec.name ~= "gundo.vim" and spec.name ~= "MatchTagAlways")) then
                vim.opt.runtimepath:append(path)
                if vim.fn.isdirectory(path .. "/after") == 1 then
                    vim.opt.runtimepath:append(path .. "/after")
                end
            end
        else
            table.insert(M.missing, spec.name)
        end
    end
    -- Arch's fzf package supplies fzf#run; fzf.vim supplies :Files/:Rg/etc.
    for _, path in ipairs({ "/usr/share/vim/vimfiles", vim.fn.expand("~/.fzf") }) do
        if vim.fn.filereadable(path .. "/plugin/fzf.vim") == 1 then
            vim.opt.runtimepath:append(path)
            break
        end
    end
    if vim.fn.isdirectory(vim.fn.expand("~/.vim/UltiSnips")) == 1 then
        vim.g.UltiSnipsSnippetDirectories = { vim.fn.expand("~/.vim/UltiSnips"), "UltiSnips" }
    end
    vim.api.nvim_create_user_command("VimMirrorInstall", function()
        if vim.fn.executable("git") == 0 then
            vim.notify("Install git first", vim.log.levels.ERROR)
            return
        end
        vim.fn.mkdir(install_root, "p")
        for _, spec in ipairs(specs) do
            local path = install_root .. "/" .. spec.name
            local shared = vim.fn.expand("~/.vim/plugged/") .. spec.name
            if vim.fn.isdirectory(path) == 0 and vim.fn.isdirectory(shared) == 0 then
                local args = { "git", "clone", "--depth=1" }
                if spec.branch then vim.list_extend(args, { "--branch", spec.branch }) end
                vim.list_extend(args, { "https://github.com/" .. spec.repo .. ".git", path })
                local result = vim.fn.system(args)
                if vim.v.shell_error ~= 0 then
                    vim.notify("Could not install " .. spec.name .. ":\n" .. result, vim.log.levels.ERROR)
                    return
                end
            end
        end
        vim.notify("Plugins available. Restart Neovim to load newly installed plugins.")
    end, { desc = "Install missing Vim-mirror plugins; never update shared Vim plugins" })
    vim.api.nvim_create_user_command("VimMirrorHealth", function()
        local messages = {
            "Python/pynvim (UltiSnips, Gundo, MatchTagAlways): " .. (M.python_available and "available" or "missing; install python-pynvim"),
            "Missing plugins: " .. (#M.missing == 0 and "none" or table.concat(M.missing, ", ")),
        }
        for _, command in ipairs({ "fzf", "rg", "git", "ctags", "jq", "xmllint", "column", "toilet", "wl-copy" }) do
            table.insert(messages, command .. ": " .. (vim.fn.executable(command) == 1 and "available" or "missing"))
        end
        vim.notify(table.concat(messages, "\n"))
    end, { desc = "Check dependencies used by this Vim configuration" })
end
return M

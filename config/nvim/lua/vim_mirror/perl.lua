local M = {}
local install_dir = vim.fn.stdpath("data") .. "/vim-mirror/perlnavigator"

function M.server()
    for _, path in ipairs({ vim.fn.exepath("perlnavigator"),
        install_dir .. "/node_modules/.bin/perlnavigator",
        vim.fn.stdpath("data") .. "/mason/bin/perlnavigator" }) do
        if path ~= "" and vim.fn.executable(path) == 1 then return path end
    end
end

function M.setup()
    vim.lsp.config("perlnavigator", {
        cmd = function(dispatchers, config)
            local server = assert(M.server(), "PerlNavigator missing: run :PerlLspInstall")
            return vim.lsp.rpc.start({ server, "--stdio" }, dispatchers, { cwd = config.root_dir })
        end,
        filetypes = { "perl" },
        root_dir = function(bufnr, on_dir)
            local file = vim.api.nvim_buf_get_name(bufnr)
            local root = vim.fs.root(file, { "cpanfile", "Makefile.PL", "Build.PL", "dist.ini", "META.json" })
            local git = vim.fs.root(file, ".git")
            if not root and git ~= vim.uv.os_homedir() and git ~= "/tmp" and git ~= "/" then root = git end
            on_dir(root or vim.fs.dirname(file) or vim.fn.getcwd())
        end,
        settings = { perlnavigator = {
            perlPath = vim.fn.exepath("perl"),
            enableWarnings = true,
            perlcriticEnabled = false,
            perlimportsLintEnabled = false,
            perlimportsTidyEnabled = false,
        } },
    })
    local function enable()
        if M.server() then vim.lsp.enable("perlnavigator"); return true end
        return false
    end
    enable()
    vim.api.nvim_create_user_command("PerlLspInstall", function()
        local pnpm = vim.fn.exepath("pnpm")
        if pnpm == "" then vim.notify("Install pnpm first", vim.log.levels.ERROR); return end
        vim.fn.mkdir(install_dir, "p")
        vim.notify("Installing PerlNavigator…")
        vim.system({ pnpm, "--dir", install_dir, "add", "perlnavigator-server" }, { text = true }, function(result)
            vim.schedule(function()
                if result.code == 0 and enable() then
                    vim.notify("PerlNavigator installed and enabled; reopen your Perl buffer")
                else
                    vim.notify("PerlNavigator installation failed:\n" .. result.stdout .. result.stderr, vim.log.levels.ERROR)
                end
            end)
        end)
    end, { desc = "Install PerlNavigator locally without sudo" })
    vim.api.nvim_create_user_command("PerlLspInfo", function()
        local clients = vim.lsp.get_clients({ name = "perlnavigator", bufnr = 0 })
        vim.notify("Server: " .. (M.server() or "missing; run :PerlLspInstall") ..
            "\nFiletype: " .. vim.bo.filetype .. "\nAttached: " .. #clients ..
            "\nRoot: " .. (clients[1] and clients[1].config.root_dir or "none") ..
            "\nLog: " .. vim.lsp.log.get_filename())
    end, { desc = "Show Perl language server status" })
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("VimMirrorPerl", { clear = true }),
        pattern = "perl", callback = function()
            if not M.server() then vim.notify("PerlNavigator missing: run :PerlLspInstall", vim.log.levels.WARN) end
        end,
    })
end

return M

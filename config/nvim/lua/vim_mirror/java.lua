local M = {}

function M.server()
    for _, path in ipairs({
        vim.fn.exepath("jdtls"),
        vim.fn.stdpath("data") .. "/mason/bin/jdtls",
    }) do
        if path ~= "" and vim.fn.executable(path) == 1 then return path end
    end
end

function M.root(bufnr)
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" then return vim.fn.getcwd() end
    -- Prefer build-wrapper/settings roots for multi-module Maven/Gradle builds.
    local build = vim.fs.root(file, { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts" })
        or vim.fs.root(file, { "pom.xml", "build.gradle", "build.gradle.kts" })
    if build then return build end
    local git = vim.fs.root(file, ".git")
    -- A home-directory dotfiles repository must not turn every standalone
    -- Java file into one giant project (including Wine's filesystem links).
    if git and git ~= vim.uv.os_homedir() and git ~= "/tmp" and git ~= "/" then return git end
    return vim.fs.dirname(file)
end

function M.workspace(root)
    local base = vim.fn.stdpath("cache") .. "/jdtls/workspaces"
    local name = vim.fs.basename(root):gsub("[^%w_.-]", "_")
    return base .. "/" .. name .. "-" .. vim.fn.sha256(root):sub(1, 16)
end

function M.setup()
    local server = M.server()
    local group = vim.api.nvim_create_augroup("VimMirrorJava", { clear = true })
    if not server then
        vim.api.nvim_create_autocmd("FileType", { group = group, pattern = "java", callback = function()
            vim.notify("Java LSP: install Eclipse jdtls, or use your Mason installation", vim.log.levels.WARN)
        end })
        return
    end

    -- Use the installed LTS JDK to run the server; project language levels
    -- continue to come from Maven/Gradle configuration.
    local java = "/usr/lib/jvm/java-25-openjdk/bin/java"
    if vim.fn.executable(java) ~= 1 then
        java = vim.env.JAVA_HOME and (vim.env.JAVA_HOME .. "/bin/java") or vim.fn.exepath("java")
    end
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    vim.lsp.config("jdtls", {
        filetypes = { "java" },
        root_dir = function(bufnr, on_dir) on_dir(M.root(bufnr)) end,
        cmd = function(dispatchers, config)
            local root = config.root_dir or vim.fn.getcwd()
            local workspace = M.workspace(root)
            vim.fn.mkdir(workspace, "p")
            return vim.lsp.rpc.start({ server, "--java-executable=" .. java, "-data", workspace },
                dispatchers, { cwd = root })
        end,
        capabilities = capabilities,
        settings = {
            java = {
                signatureHelp = { enabled = true },
                contentProvider = { preferred = "fernflower" },
                eclipse = { downloadSources = true },
                maven = { downloadSources = true },
                configuration = { updateBuildConfiguration = "interactive" },
                format = { enabled = true, settings = {} },
                completion = { importOrder = { "java", "javax", "org", "com" } },
            },
        },
        init_options = { bundles = {} },
    })

    vim.diagnostic.config({ severity_sort = true, underline = true, signs = true,
        virtual_text = { spacing = 2, source = "if_many" }, float = { border = "rounded", source = true } })
    vim.api.nvim_create_user_command("JavaLspInfo", function()
        local root = M.root(0)
        local clients = vim.lsp.get_clients({ name = "jdtls", bufnr = 0 })
        vim.notify("Server: " .. server .. "\nJava: " .. java .. "\nRoot: " .. root ..
            "\nWorkspace: " .. M.workspace(root) .. "\nFiletype: " .. vim.bo.filetype ..
            "\nAttached: " .. #clients .. "\nInitialized: " .. tostring(clients[1] and clients[1].initialized or false) ..
            "\nCompletion: " .. tostring(clients[1] and clients[1].server_capabilities.completionProvider ~= nil or false) ..
            "\nLog: " .. vim.lsp.log.get_filename())
    end, { desc = "Show Java server, JDK and per-project workspace" })
    vim.lsp.enable("jdtls")
end

return M

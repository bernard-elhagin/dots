local function install()
    local data = vim.fn.stdpath("data")
    local missing = {}
    for _, name in ipairs({ "jdtls", "perlnavigator" }) do
        local available = vim.fn.executable(name) == 1
            or vim.fn.executable(data .. "/mason/bin/" .. name) == 1
        if name == "perlnavigator" then
            available = available or vim.fn.executable(data .. "/vim-mirror/perlnavigator/node_modules/.bin/perlnavigator") == 1
        end
        if available then print(name .. ": already installed") else missing[#missing + 1] = name end
    end
    if #missing == 0 then return end

    vim.opt.runtimepath:prepend(assert(vim.env.DOTS_MASON_DIR, "DOTS_MASON_DIR missing"))
    require("mason").setup({ install_root_dir = data .. "/mason" })
    local registry = require("mason-registry")
    local refreshed, registry_ok, registry_error = false, false, nil
    registry.refresh(function(ok, result)
        registry_ok, registry_error, refreshed = ok, result, true
    end)
    assert(vim.wait(120000, function() return refreshed end, 100), "Mason registry refresh timed out")
    assert(registry_ok, "Mason registry refresh failed: " .. vim.inspect(registry_error))
    for _, name in ipairs(missing) do
        local package = registry.get_package(name)
        local finished, succeeded, detail = false, false, nil
        print("Installing " .. name .. "…")
        package:install({}, function(ok, result)
            succeeded, detail, finished = ok, result, true
        end)
        assert(vim.wait(600000, function() return finished end, 100), name .. " installation timed out")
        assert(succeeded and package:is_installed(), name .. " installation failed: " .. vim.inspect(detail))
        assert(vim.fn.executable(data .. "/mason/bin/" .. name) == 1, name .. " executable missing")
        print(name .. ": installed")
    end
end

local ok, err = pcall(install)
if not ok then
    io.stderr:write(tostring(err) .. "\nSee " .. vim.fn.stdpath("state") .. "/mason.log for details.\n")
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end

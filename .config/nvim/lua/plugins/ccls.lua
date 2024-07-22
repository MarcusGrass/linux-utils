local cfg = function()
    local shared = require("pluginit.lsp-shared")

    require("ccls").setup({
        lsp = {
            server = {
                name = "ccls",
                cmd = { "/usr/bin/ccls" },
                init_options = {
                    cache = {
                        directory = vim.fs.normalize "~/.cache/ccls/",
                    }
                },
                root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]), -- or some other function that returns a string
                on_attach = shared.lsp_do_attach,
                --capabilities = my_caps_table_or_func

            }
        }
    })
end
return {
    "ranjithshegde/ccls.nvim",
    config = cfg,
}

local shared = require("pluginit.lsp-shared")

shared.nvim_lsp.pylsp.setup({
    on_attach = shared.lsp_do_attach,
})

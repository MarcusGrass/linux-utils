local shared = require('pluginit.lsp-shared')

shared.nvim_lsp.zls.setup({
    on_attach = shared.lsp_do_attach
})


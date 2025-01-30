--- Lsp setup
---

local shared_on_attach = require("util.lsp_attach")
local shared = {}
shared.nvim_lsp = require("lspconfig")
shared.lsp_status = require("lsp-status")


shared.lsp_status.register_progress()

function shared.lsp_do_attach(client, bufnr)
    shared_on_attach.lsp_do_attach(client, bufnr)

    shared.lsp_status.on_attach(client)
end

return shared

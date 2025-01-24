--- File browser
local cfg = function()
    local function my_on_attach(bufnr)
        local api = require("nvim-tree.api")
        local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "<C-ENTER>", api.tree.change_root_to_node, opts("CD"))
    end

    require("nvim-tree").setup({
        on_attach = my_on_attach,
        open_on_tab = true,

        git = {
            enable = true,
            ignore = true,
            timeout = 500,
        },
        diagnostics = {
            enable = true,
            icons = {
                hint = "",
                info = "",
                warning = "",
                error = "",
            },
        },
        view = {
            width = 30,
        },
    })
end

return { "nvim-tree/nvim-tree.lua", config = cfg }

local cfg = function(_, opts)
    local function on_move(data)
        require("snacks").rename.on_rename_file(data.source, data.destination)
    end
    local events = require("neo-tree.events")
    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
    })
    require("neo-tree").setup({
        window = {
            mappings = {
                ["<leader>nf"] = {
                    function(state)
                        local node = state.tree:get_node()
                        if node == nil then
                            vim.notify("Neotree failed to get node (was nil)", vim.log.levels.ERROR, nil)
                            return
                        end
                        local path = node.path
                        if path == nil then
                            vim.notify("Neotree failed to get node path (was nil)", vim.log.levels.ERROR, nil)
                            return
                        end
                        vim.cmd(string.format(':lua Snacks.picker.pick("grep", { dirs = { "%s" } })', path))
                    end,
                },
            },
        },
        filesystem = {
            filtered_items = {
                hijack_netrw_behavior = "open_current",
            },
        },
        auto_clean_after_session_restore = true,
    })
end
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    config = cfg,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
}

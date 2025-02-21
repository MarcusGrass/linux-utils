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
                ["<C-ENTER>"] = {
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
                        require("plug-ext.window-picker-ext.open").open_path_over_win(path)
                    end,
                },
                ["s"] = {
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
                        require("plug-ext.window-picker-ext.open").open_path_hsplit_at_win(path)
                    end,
                },
                ["S"] = {
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
                        require("plug-ext.window-picker-ext.open").open_path_vsplit_at_win(path)
                    end,
                },
            },
        },
        filesystem = {
            bind_to_cwd = true,
            filtered_items = {},
            follow_current_file = {
                enabled = false, -- This will find and focus the file in the active buffer every time
            },
            hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
            use_libuv_file_watcher = true,
            window = {
                mappings = {
                    ["h"] = { "navigate_up", desc = "Navigate up" },
                    ["l"] = { "set_root", desc = "Navigate down" },
                },
            },
        },
        buffers = {
            follow_current_file = {
                enabled = false, -- This will find and focus the file in the active buffer every time
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

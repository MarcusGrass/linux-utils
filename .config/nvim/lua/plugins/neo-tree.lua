return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    opts = function(_, opts)
        local key = require("util.keymap")
        local function on_move(data)
            require("snacks").rename.on_rename_file(data.source, data.destination)
        end
        local events = require("neo-tree.events")
        opts.event_handlers = opts.event_handlers or {}
        vim.list_extend(opts.event_handlers, {
            { event = events.FILE_MOVED, handler = on_move },
            { event = events.FILE_RENAMED, handler = on_move },
        })
        -- Switch focus to file tree
        key.mapn("<leader>nb", ":Neotree focus buffers<CR>")
        key.mapn("<leader>ng", ":Neotree focus git_status<CR>")

        -- Collapse all files in tree
        key.mapn("<leader>nc", ":Neotree close<CR>")
        -- Open tree at current file
        key.mapnfn("<leader>no", function()
            local reveal_file = vim.fn.expand("%:p")
            if reveal_file == "" then
                reveal_file = vim.fn.getcwd()
            else
                local f = io.open(reveal_file, "r")
                if f then
                    f.close(f)
                else
                    reveal_file = vim.fn.getcwd()
                end
            end
            require("neo-tree.command").execute({
                action = "focus", -- OPTIONAL, this is the default value
                source = "filesystem", -- OPTIONAL, this is the default value
                position = "left", -- OPTIONAL, this is the default value
                reveal_file = reveal_file, -- path to file or folder to reveal
            })
        end, { desc = "Open neo-tree at current file or working directory" })

        --- Try to open to current buffer in a new tab.
        --- Preserves location.
        --- Preserves the old buffer in the old tab.
        --- Mostly used for browsing dependencies separately, after navigating to a file in the dependency.
        key.mapnfn("<leader>nn", function()
            local cur_buf = vim.fn.expand("%")
            if cur_buf == "" then
                vim.notify("Buf with no name, can't go-to", vim.log.levels.WARN)
                return
            end
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            local f = io.open(cur_buf, "r")
            if f then
                f.close(f)
            else
                vim.notify(string.format("failed to open %s can't go-to", cur_buf), vim.log.levels.WARN)
                return
            end
            vim.cmd(string.format(":tabnew %s", cur_buf))
            vim.api.nvim_win_set_cursor(0, { line, col })
            require("neo-tree.command").execute({
                action = "show", -- OPTIONAL, this is the default value
                source = "filesystem", -- OPTIONAL, this is the default value
                position = "left", -- OPTIONAL, this is the default value
                reveal_file = cur_buf, -- path to file or folder to reveal
                reveal_force_cwd = true, -- switch cwd without asking
            })
        end, { desc = "Open neo-tree at current file or working directory" })

        return vim.tbl_deep_extend("force", opts or {}, {
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
    end,
}

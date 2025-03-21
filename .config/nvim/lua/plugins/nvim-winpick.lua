local default_chars = "OEUHTNAIDSCRL"
local pick_relative_chars = "ESUATNDOH"
return {
    dir = "/home/gramar/code/rust/nvim_winpick",
    --"MarcusGrass/nvim_winpick",
    --branch = "x86_64-unknown-linux-gnu-latest",
    lazy = false,
    opts = {
        selection_chars = default_chars,
        multiselect = {
            trigger_char = "m",
            commit_char = "c",
        },
    },
    keys = {
        {
            "<leader>h",
            function()
                require("nvim_winpick").pick_focus_window({
                    selection_chars = default_chars,
                    filter_rules = {
                        autoselect_one = false,
                        include_current_win = true,
                        bo = {
                            -- Don't skip anything
                            buftype = {},
                            filetype = {},
                        },
                    },
                })
            end,
        },
        {
            "<leader>wd",
            function()
                require("nvim_winpick").pick_close_window({
                    selection_chars = default_chars,
                    multiselect = {
                        trigger_char = "m",
                        commit_char = "c",
                    },
                    filter_rules = {
                        autoselect_one = false,
                        include_current_win = true,
                        bo = {
                            -- Don't skip anything
                            buftype = {},
                            filetype = {},
                        },
                    },
                })
            end,
        },
        {
            "<leader>wu",
            function()
                require("nvim_winpick").pick_win_relative({
                    path = vim.fn.expand("%"),
                    focus_new = false,
                })
            end,
        },
        {
            "<leader>ws",
            function()
                require("nvim_winpick").pick_swap_window()
            end,
        },
    },
    specs = {
        {
            "folke/snacks.nvim",
            opts = function(_, opts)
                local edit_pick_win = {
                    action = function(picker, item)
                        local file = item.file
                        picker:close()
                        require("nvim_winpick").pick_win_relative({
                            path = file,
                            relative_chars = pick_relative_chars,
                            opts = {
                                selection_chars = default_chars,
                            },
                        })
                    end,
                    desc = "edit confirm which window to use",
                }

                local edit_hsplit_pick_win = {
                    action = function(picker, item)
                        local file = item.file
                        picker:close()
                        require("nvim_winpick").pick_open_split({
                            path = file,
                            vertical = true,
                            focus_new = true,
                        })
                    end,

                    desc = "edit_hsplit confirm which window to split",
                }

                local edit_vsplit_pick_win = {
                    action = function(picker, item)
                        local file = item.file
                        picker:close()
                        require("nvim_winpick").pick_open_split({
                            path = file,
                            vertical = false,
                            focus_new = true,
                        })
                    end,

                    desc = "edit_vsplit confirm which window to split",
                }
                return vim.tbl_deep_extend("force", opts or {}, {
                    picker = {
                        actions = {
                            edit_vsplit_pick_win = edit_vsplit_pick_win,
                            edit_hsplit_pick_win = edit_hsplit_pick_win,
                            edit_pick_win = edit_pick_win,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<C-ENTER>"] = { "edit_pick_win", mode = { "n", "i" } },
                                    ["<C-s>"] = { "edit_hsplit_pick_win", mode = { "n", "i" } },
                                    ["<C-v>"] = { "edit_vsplit_pick_win", mode = { "n", "i" } },
                                },
                            },
                        },
                    },
                })
            end,
        },
        {
            "nvim-neo-tree/neo-tree.nvim",
            opts = function(_, opts)
                return vim.tbl_deep_extend("force", opts or {}, {
                    window = {
                        mappings = {
                            ["<C-ENTER>"] = {
                                function(state)
                                    local node = state.tree:get_node()
                                    if node == nil then
                                        vim.notify("Neotree failed to get node (was nil)", vim.log.levels.ERROR, nil)
                                        return
                                    end
                                    local path = node.path
                                    if path == nil then
                                        vim.notify(
                                            "Neotree failed to get node path (was nil)",
                                            vim.log.levels.ERROR,
                                            nil
                                        )
                                        return
                                    end
                                    require("nvim_winpick").pick_win_relative({
                                        path = path,
                                        relative_chars = pick_relative_chars,
                                        opts = {
                                            selection_chars = default_chars,
                                        },
                                    })
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
                                        vim.notify(
                                            "Neotree failed to get node path (was nil)",
                                            vim.log.levels.ERROR,
                                            nil
                                        )
                                        return
                                    end
                                    require("nvim_winpick").pick_open_split({
                                        path = path,
                                        vertical = false,
                                        focus_new = true,
                                    })
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
                                        vim.notify(
                                            "Neotree failed to get node path (was nil)",
                                            vim.log.levels.ERROR,
                                            nil
                                        )
                                        return
                                    end
                                    require("nvim_winpick").pick_open_split({
                                        path = path,
                                        vertical = true,
                                        focus_new = true,
                                    })
                                end,
                            },
                        },
                    },
                })
            end,
        },
    },
}

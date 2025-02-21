return {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    version = "2.*",
    event = "VeryLazy",
    opts = {
        hint = "floating-big-letter",
        selection_chars = "AOEUIDHTNS,.pyfgcrl",
        filter_rules = {
            autoselect_one = false,
            include_current_win = true,
            include_unfocusable_windows = true,
            bo = {
                filetype = {},
                buftype = {},
            },
        },
        show_prompt = false,
    },
    specs = {
        "folke/snacks.nvim",
        opts = function(_, opts)
            local edit_pick_win = {
                action = function(picker, item)
                    local pickers = require("plug-ext.window-picker-ext.custom_pickers")
                    local file = item.file
                    picker:close()
                    require("plug-ext.window-picker-ext.open").open_path_over_win(file, pickers.snacks_picker_opts)
                end,

                desc = "edit confirm which window to use",
            }

            local edit_hsplit_pick_win = {
                action = function(picker, item)
                    local pickers = require("plug-ext.window-picker-ext.custom_pickers")
                    local file = item.file
                    picker:close()
                    require("plug-ext.window-picker-ext.open").open_path_hsplit_at_win(file, pickers.snacks_picker_opts)
                end,

                desc = "edit_hsplit confirm which window to split",
            }

            local edit_vsplit_pick_win = {
                action = function(picker, item)
                    local pickers = require("plug-ext.window-picker-ext.custom_pickers")
                    local file = item.file
                    picker:close()
                    require("plug-ext.window-picker-ext.open").open_path_vsplit_at_win(file, pickers.snacks_picker_opts)
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
}

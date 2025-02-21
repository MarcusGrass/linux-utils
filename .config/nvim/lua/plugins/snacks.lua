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

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        bigfile = { enabled = false },
        dashboard = {
            enabled = true,
            sections = {
                { section = "header" },
                { section = "keys", gap = 1, padding = 1 },
                { section = "startup" },
                {
                    pane = 2,
                    icon = " ",
                    key = "s",
                    title = "Sessions",
                    section = "session",
                    action = ":lua require('persistence').select()",
                    indent = 2,
                    padding = 1,
                },
                { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                {
                    pane = 2,
                    icon = " ",
                    title = "Git Status",
                    section = "terminal",
                    enabled = function()
                        return require("snacks").git.get_root() ~= nil
                    end,
                    cmd = "git status --short --branch --renames",
                    height = 5,
                    padding = 1,
                    ttl = 5 * 60,
                    indent = 3,
                },
            },
        },
        indent = { enabled = false },
        input = { enabled = true },
        picker = {
            enabled = true,
            win = {
                input = {
                    keys = {
                        ["<C-ENTER>"] = { "edit_pick_win", mode = { "n", "i" } },
                        ["<C-s>"] = { "edit_hsplit_pick_win", mode = { "n", "i" } },
                        ["<C-v>"] = { "edit_vsplit_pick_win", mode = { "n", "i" } },
                    },
                },
            },
            actions = {
                edit_vsplit_pick_win = edit_vsplit_pick_win,
                edit_hsplit_pick_win = edit_hsplit_pick_win,
                edit_pick_win = edit_pick_win,
            },
        },
        terminal = {
            enabled = true,
            win = {
                wo = {
                    winbar = "",
                },
            },
        },
        notifier = {
            enabled = true,
            timeout = 10000,
        },
        quickfile = { enabled = false },
        scroll = { enabled = false },
        statuscolumn = { enabled = false },
        words = { enabled = false },
        styles = {
            terminal = {
                keys = {
                    term_normal = {
                        "<esc>",
                        function(self)
                            self.esc_timer = self.esc_timer or vim.uv.new_timer()
                            if self.esc_timer:is_active() then
                                self.esc_timer:stop()
                                vim.cmd("stopinsert")
                            else
                                self.esc_timer:start(750, 0, function() end)
                                return "<esc>"
                            end
                        end,
                        mode = "t",
                        expr = true,
                        desc = "Double escape to normal mode",
                    },
                },
            },
            notification = {
                wo = {
                    wrap = true,
                },
            },
        },
    },
}

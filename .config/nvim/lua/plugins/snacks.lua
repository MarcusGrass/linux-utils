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
                    keys = {},
                },
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
        },
    },
}

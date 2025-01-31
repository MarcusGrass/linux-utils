return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        bigfile = { enabled = false },
        dashboard = { enabled = false },
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
        notifier = { enabled = true },
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
                            self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
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

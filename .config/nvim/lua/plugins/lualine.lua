local cfg = function()
    require("lualine").setup({
        options = {
            theme = "catppuccin",
            globalstatus = true,
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { { "filename", file_status = true, path = 1 } },
            lualine_x = {
                function()
                    return require("lsp-status").status()
                end,
            },
            lualine_y = {},
            lualine_z = {},
        },
        always_show_tabline = true,
        tabline = {
            lualine_a = {"buffers"},
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {"tabs"},
        }
    })
end
-- Airline bottom bar
return {
    "nvim-lualine/lualine.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = cfg,
}

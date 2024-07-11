local cfg = function()
    require('lualine').setup {
        options = {
            theme = "catppuccin",
            globalstatus = true,
        },
        sections = {
            lualine_a = {'mode'},
            lualine_b = {'branch', 'diff', 'diagnostics'},
            lualine_c = { {'filename', file_status = true, path = 1} },
            lualine_x = {
                function()
                    return require("lsp-status").status()
                end
            },
            lualine_y = {},
            lualine_z = {},
        },
    }
end
-- Airline bottom bar
return { 
    'nvim-lualine/lualine.nvim',
    requires = "nvim-tree/nvim-web-devicons",
    config = cfg,
}

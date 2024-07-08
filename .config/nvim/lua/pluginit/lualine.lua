--- Lualine
require('lualine').setup {
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = { {'filename', file_status = true, path = 2} },
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress', {'lsp_progress', display_components = { { 'title', 'percentage' }},}},
        lualine_z = {'location'}
    },
}



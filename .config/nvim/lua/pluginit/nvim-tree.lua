--- File browser
require'nvim-tree'.setup {
    open_on_tab         = true,

    git = {
        enable = true,
        ignore = true,
        timeout = 500,
    },
    diagnostics = {
        enable = true,
        icons = {
            hint = "",
            info = "",
            warning = "",
            error = "",
        }
    },
    view = {
        width = 30,
    },
}



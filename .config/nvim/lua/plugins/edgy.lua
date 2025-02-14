return {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
        vim.opt.laststatus = 3
        vim.opt.splitkeep = "screen"
    end,
    opts = {
        animate = {
            enabled = false,
        },
        bottom = {
            {
                ft = "snacks_terminal",
                size = { height = 0.25, width = 0.5 },
                title = "%{b:snacks_terminal.id}: %{b:term_title}",
                filter = function(_buf, win)
                    return vim.w[win].snacks_win
                        and vim.w[win].snacks_win.position == "bottom"
                        and vim.w[win].snacks_win.relative == "editor"
                        and not vim.w[win].trouble_preview
                end,
                open = "lua Snacks.terminal.toggle()",
                wo = {
                    winbar = false, -- Annoying with winbar on term
                },
            },
            {
                title = "Trouble",
                ft = "trouble",
                size = { height = 0.25, width = 0.5 },
                open = "Trouble split_preview focus",
            },
        },
        left = {
            {
                title = "NeoTree",
                ft = "neo-tree",
                filter = function(buf)
                    return vim.b[buf].neo_tree_source == "filesystem"
                end,
                size = { height = 0.5 },
                pinned = true,
                open = "Neotree",
            },
            {
                title = "Neo-Tree Buffers",
                ft = "neo-tree",
                filter = function(buf)
                    return vim.b[buf].neo_tree_source == "buffers"
                end,
                size = { height = 0.5 },
                pinned = true,
                collapsed = false,
                open = "Neotree position=right buffers",
            },
        },
        right = {
            {
                title = "Neo-Tree Git",
                ft = "neo-tree",
                filter = function(buf)
                    return vim.b[buf].neo_tree_source == "git_status"
                end,
                size = { height = 0.50 },
                pinned = true,
                collapsed = false, -- show window as closed/collapsed on start
                open = "Neotree position=top git_status",
            },
            {
                title = "Aerial",
                ft = "aerial",
                size = { height = 0.5 },
            },
        },
        top = {
            {
                ft = "help",
                size = { height = 0.5 },
                filter = function(buf)
                    return vim.bo[buf].buftype == "help"
                end,
            },
        },
    },
}

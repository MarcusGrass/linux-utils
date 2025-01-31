return {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
        vim.opt.laststatus = 3
        vim.opt.splitkeep = "screen"
    end,
    opts = {
        bottom = {
            {
                ft = "snacks_terminal",
                size = { height = 0.25 },
                title = "%{b:snacks_terminal.id}: %{b:term_title}",
                filter = function(_buf, win)
                    return vim.w[win].snacks_win
                        and vim.w[win].snacks_win.position == "bottom"
                        and vim.w[win].snacks_win.relative == "editor"
                        and not vim.w[win].trouble_preview
                end,
            },
            "Trouble",
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
                collapsed = false,
                open = "Neotree",
            },
            {
                title = "Neo-Tree Git",
                ft = "neo-tree",
                filter = function(buf)
                    return vim.b[buf].neo_tree_source == "git_status"
                end,
                pinned = true,
                collapsed = false, -- show window as closed/collapsed on start
                open = "Neotree position=right git_status",
            },
            {
                title = "Neo-Tree Buffers",
                ft = "neo-tree",
                filter = function(buf)
                    return vim.b[buf].neo_tree_source == "buffers"
                end,
                pinned = true,
                collapsed = false, -- show window as closed/collapsed on start
                open = "Neotree position=top buffers",
            },
        },
    },
}

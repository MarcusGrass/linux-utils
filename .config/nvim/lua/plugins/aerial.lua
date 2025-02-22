return {
    "stevearc/aerial.nvim",
    opts = function(_, opts)
        local key = require("util.keymap")
        -- Toggle aerial
        key.mapn("<leader>aet", ":AerialToggle!<CR>")

        return vim.tbl_deep_extend("force", opts or {}, {
            backends = { "lsp", "treesitter", "markdown" },

            -- Set to false to remove the default keybindings for the aerial buffer
            default_bindings = true,

            -- Enum: prefer_right, prefer_left, right, left, float
            -- Determines the default direction to open the aerial window. The 'prefer'
            -- options will open the window in the other direction *if* there is a
            -- different buffer in the way of the preferred direction
            layout = {},

            -- Disable aerial on files with this many lines
            disable_max_lines = 10000,

            -- A list of all symbols to display. Set to false to display all symbols.
            -- This can be a filetype map (see :help aerial-filetype-map)
            -- To see all available values, see :help SymbolKind
            filter_kind = false,
            -- Automatically open aerial when entering supported buffers.
            -- This can be a function (see :help aerial-open-automatic)
            open_automatic = false,
            -- Run this command after jumping to a symbol (false will disable)
            post_jump_cmd = "normal! zz",
        })
    end,
}

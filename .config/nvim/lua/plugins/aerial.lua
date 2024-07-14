-- Symbol window
local cfg = function()
    require("aerial").setup({
        -- Priority list of preferred backends for aerial.
        -- This can be a filetype map (see :help aerial-filetype-map)
        backends = { "lsp", "treesitter", "markdown" },

        -- Set to false to remove the default keybindings for the aerial buffer
        default_bindings = true,

        -- Enum: prefer_right, prefer_left, right, left, float
        -- Determines the default direction to open the aerial window. The 'prefer'
        -- options will open the window in the other direction *if* there is a
        -- different buffer in the way of the preferred direction
        layout = {
            default_direction = "prefer_right",
        },

        -- Disable aerial on files with this many lines
        disable_max_lines = 10000,

        -- A list of all symbols to display. Set to false to display all symbols.
        -- This can be a filetype map (see :help aerial-filetype-map)
        -- To see all available values, see :help SymbolKind
        filter_kind = false,
        -- Automatically open aerial when entering supported buffers.
        -- This can be a function (see :help aerial-open-automatic)
        open_automatic = true,
        -- Run this command after jumping to a symbol (false will disable)
        post_jump_cmd = "normal! zz",
    })
end

return { "stevearc/aerial.nvim", config = cfg }

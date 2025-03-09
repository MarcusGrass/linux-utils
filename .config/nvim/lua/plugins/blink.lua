return {
    {
        "saghen/blink.compat",
        -- use the latest release, via version = '*', if you also use the latest release for blink.cmp
        version = "*",
        -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
        lazy = true,
        -- make sure to set opts so that lazy.nvim calls blink.compat's setup
        opts = {},
    },
    {
        "saghen/blink.cmp",
        dependencies = "rafamadriz/friendly-snippets",
        -- From source always
        build = "cargo build --release",
        opts = {
            keymap = {
                preset = "default",
                ["<TAB>"] = { "select_and_accept" },
            },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 0, update_delay_ms = 0 },
                ghost_text = {
                    -- Glitchy but I like it
                    enabled = true,
                },
            },

            sources = {
                default = { "lsp", "crates", "path", "snippets", "buffer" },
                providers = {
                    crates = {
                        name = "crates",
                        module = "blink.compat.source",
                    },
                },
            },

            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
        opts_extend = { "sources.default" },
    },
}

return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            rust = { "rustfmt" },
            json = { "jq" },
        },
        format_on_save = {
            timeout_ms = 500,
        },
    },
}

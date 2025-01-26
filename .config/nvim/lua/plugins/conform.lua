local cfg = function()
    require("conform").setup({
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            rust = { "rustfmt" },
            json = { "jq" },
        },
        format_on_save = {
            timeout_ms = 500,
        },
    })
end

return {
    "stevearc/conform.nvim",
    opts = {},
    config = cfg,
}

local cfg = function ()
    require("conform").setup({
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            rust = { "rustfmt" },
        }
    })
end

return {
    "stevearc/conform.nvim",
    opts = {},
    config = cfg,
}

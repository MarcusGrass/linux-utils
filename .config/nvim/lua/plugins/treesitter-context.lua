--- Syntax highlighting, language specific
local cfg = function()
    require("treesitter-context").setup({
        enable = true,
        max_lines = 0,
    })
end
return {
    "nvim-treesitter/nvim-treesitter-context",
    config = cfg,
}

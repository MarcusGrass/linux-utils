local cfg = function(_, opts)
    vim.keymap.set("n", "<leader>qS", function()
        require("persistence").select()
    end)
    require("persistence").setup(opts)
end
return {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    config = cfg,
}

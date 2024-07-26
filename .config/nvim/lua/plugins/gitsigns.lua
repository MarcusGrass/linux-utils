local cfg = function()
    require("gitsigns").setup({
        numhl = true,
    })
end
return { "lewis6991/gitsigns.nvim", config = cfg }

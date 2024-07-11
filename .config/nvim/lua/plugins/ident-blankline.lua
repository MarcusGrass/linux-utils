--- Show blank lines in indentation

return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
        require('ibl').setup()
    end
}

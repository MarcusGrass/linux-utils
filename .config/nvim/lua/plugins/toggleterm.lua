--- Terminal
local cfg = function()
    require("toggleterm").setup({
        shade_terminals = true,
        close_on_exit = true,
        size = 60,
    })

    function _G.set_terminal_keymaps()
        local opts = { noremap = true }
        vim.api.nvim_buf_set_keymap(0, "t", "<esc><esc>", [[<C-\><C-n>]], opts)
    end

    -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
end
return { "akinsho/toggleterm.nvim", config = cfg }

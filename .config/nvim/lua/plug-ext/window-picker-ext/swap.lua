local M = {}

M.swap_with_current = function()
    local win = vim.api.nvim_get_current_win()
    if not win then
        return
    end
    local cur_buf = vim.api.nvim_win_get_buf(win)
    if not cur_buf then
        return
    end
    local target = require("window-picker").pick_window()
    if not target then
        return
    end
    local target_buf = vim.api.nvim_win_get_buf(target)
    if not target_buf then
        return
    end
    vim.api.nvim_win_set_buf(win, target_buf)
    vim.api.nvim_win_set_buf(target, cur_buf)
    vim.api.nvim_set_current_win(win)
end

return M

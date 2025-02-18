local M = {}
M.select_focus_window = function()
    local target = require("window-picker").pick_window()
    if not target then
        return
    end
    vim.api.nvim_set_current_win(target)
end

M.close_focus_window = function()
    local target = require("window-picker").pick_window()
    if not target then
        return
    end
    vim.api.nvim_win_close(target, false)
end
return M

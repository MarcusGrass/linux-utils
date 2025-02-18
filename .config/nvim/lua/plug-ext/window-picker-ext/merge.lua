local M = {}

M.merge_current_with_vertical = function()
    local win = vim.api.nvim_get_current_win()
    if not win then
        return
    end
    local target = require("window-picker").pick_window()
    if not target then
        return
    end
    -- Todo
end

return M

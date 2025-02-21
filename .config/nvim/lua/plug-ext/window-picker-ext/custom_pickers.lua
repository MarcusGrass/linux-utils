local M = {}
M.snacks_picker_opts = {
    filter_func = function(windows)
        local filter = require("plug-ext.window-picker-ext.filter")
        local filtered = {}
        for _, win in pairs(windows) do
            if filter.file_backed_win_filter(win) then
                filtered[#filtered + 1] = win
            end
        end
        return filtered
    end,
}
return M

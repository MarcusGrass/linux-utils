local M = {}
M.file_backed_win_filter = function(win)
    local floating = vim.api.nvim_win_get_config(win).relative ~= ""
    return not floating
end
return M

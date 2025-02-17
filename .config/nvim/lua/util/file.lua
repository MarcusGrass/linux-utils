local M = {}

M.get_current_file = function()
    local cur_file = vim.fn.expand("%")
    if cur_file == "" then
        return nil
    end
    return cur_file
end

return M

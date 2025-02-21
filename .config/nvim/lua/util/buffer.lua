local M = {}
M.load_file_to_hidden_buffer = function(node)
    local bufnr = vim.fn.bufadd(node)
    vim.fn.bufload(bufnr)
    return bufnr
end
return M

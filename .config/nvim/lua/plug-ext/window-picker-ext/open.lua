local M = {}
M.open_buf_vsplit_at_win = function(bufnr, opts)
    local target = require("window-picker").pick_window(opts)
    if not target then
        return
    end
    vim.api.nvim_open_win(bufnr, true, {
        win = target,
        split = "below",
    })
end

M.open_path_vsplit_at_win = function(node, opts)
    local bufnr = require("util.buffer").load_file_to_hidden_buffer(node)
    M.open_buf_vsplit_at_win(bufnr, opts)
end

M.open_buf_hsplit_at_win = function(bufnr, opts)
    local target = require("window-picker").pick_window(opts)
    if not target then
        return
    end
    vim.api.nvim_open_win(bufnr, true, {
        win = target,
        split = "left",
    })
end

M.open_path_hsplit_at_win = function(node, opts)
    local bufnr = require("util.buffer").load_file_to_hidden_buffer(node)
    M.open_buf_hsplit_at_win(bufnr, opts)
end
M.open_buf_over_win = function(bufnr, opts)
    local target = require("window-picker").pick_window(opts)
    if not target then
        return
    end
    vim.api.nvim_win_set_buf(target, bufnr)
    vim.api.nvim_set_current_win(target)
end
M.open_path_over_win = function(node, opts)
    local bufnr = require("util.buffer").load_file_to_hidden_buffer(node)
    M.open_buf_over_win(bufnr, opts)
end
return M

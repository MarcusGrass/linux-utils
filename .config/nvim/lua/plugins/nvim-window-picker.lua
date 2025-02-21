local filter_buf = function(win)
    local wincfg = vim.api.nvim_win_get_config(win)
    if not wincfg.focusable or wincfg.relative ~= "" then
        return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    if not buf then
        return true
    end
    local wininfo = vim.fn.getwininfo(win)
    for _, wintable in pairs(wininfo) do
        local is_terminal = wintable.terminal ~= 0
        if is_terminal then
            return false
        end
        local bufnr = wintable.bufnr
        local bufinfo = vim.fn.getbufinfo(bufnr)
        for _, buftable in pairs(bufinfo) do
            if buftable.name:find("edgy://", nil, true) then
                return false
            end
            if buftable.name:find("neo-tree filesystem", nil, true) then
                return false
            end
        end
    end
    return true
end

local place_window_opts = {
    filter_func = function(windows)
        local filtered = {}
        for _, win in pairs(windows) do
            if filter_buf(win) then
                filtered[#filtered + 1] = win
            end
        end
        return filtered
    end,
    filter_rules = {
        bo = {
            filetype = { "neo-tree", "notify", "snacks_notif" },
            buftype = { "terminal" },
        },
    },
}

local select_focus_window = function()
    local target = require("window-picker").pick_window()
    if not target then
        return
    end
    vim.api.nvim_set_current_win(target)
end

local close_focus_window = function()
    local target = require("window-picker").pick_window()
    if not target then
        return
    end
    vim.api.nvim_win_close(target, false)
end

local swap_with_current = function(opts)
    local win = vim.api.nvim_get_current_win()
    if not win then
        return
    end
    local cur_buf = vim.api.nvim_win_get_buf(win)
    if not cur_buf then
        return
    end
    local target = require("window-picker").pick_window(opts)
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

local open_buf_vsplit_at_win = function(bufnr, opts)
    local target = require("window-picker").pick_window(opts)
    if not target then
        return
    end
    vim.api.nvim_open_win(bufnr, true, {
        win = target,
        split = "below",
    })
end

local open_path_vsplit_at_win = function(node, opts)
    local bufnr = require("util.buffer").load_file_to_hidden_buffer(node)
    open_buf_vsplit_at_win(bufnr, opts)
end

local open_buf_hsplit_at_win = function(bufnr, opts)
    local target = require("window-picker").pick_window(opts)
    if not target then
        return
    end
    vim.api.nvim_open_win(bufnr, true, {
        win = target,
        split = "left",
    })
end

local open_path_hsplit_at_win = function(node, opts)
    local bufnr = require("util.buffer").load_file_to_hidden_buffer(node)
    open_buf_hsplit_at_win(bufnr, opts)
end
local open_buf_over_win = function(bufnr, opts)
    local target = require("window-picker").pick_window(opts)
    if not target then
        return
    end
    vim.api.nvim_win_set_buf(target, bufnr)
    vim.api.nvim_set_current_win(target)
end
local open_path_over_win = function(node, opts)
    local bufnr = require("util.buffer").load_file_to_hidden_buffer(node)
    open_buf_over_win(bufnr, opts)
end

return {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    version = "2.*",
    event = "VeryLazy",
    opts = function(_, opts)
        local key = require("util.keymap")
        -- Pick focus window
        key.mapnfn("<leader>h", function()
            select_focus_window()
        end)
        -- close a window
        key.mapnfn("<leader>wd", function()
            close_focus_window()
        end)
        -- Swap a window
        key.mapnfn("<leader>ws", function()
            swap_with_current(place_window_opts)
        end)

        return vim.tbl_deep_extend("force", opts or {}, {
            hint = "floating-big-letter",
            selection_chars = "OEUHTNAS,.PCRL",
            filter_rules = {
                autoselect_one = false,
                include_current_win = true,
                include_unfocusable_windows = true,
                bo = {
                    filetype = { "neo-tree", "notify", "snacks_notif" },
                    buftype = { "terminal" },
                },
            },
            show_prompt = false,
        })
    end,
    specs = {
        {
            "folke/snacks.nvim",
            opts = function(_, opts)
                local edit_pick_win = {
                    action = function(picker, item)
                        local file = item.file
                        picker:close()
                        open_path_over_win(file, place_window_opts)
                    end,

                    desc = "edit confirm which window to use",
                }

                local edit_hsplit_pick_win = {
                    action = function(picker, item)
                        local file = item.file
                        picker:close()
                        open_path_hsplit_at_win(file, place_window_opts)
                    end,

                    desc = "edit_hsplit confirm which window to split",
                }

                local edit_vsplit_pick_win = {
                    action = function(picker, item)
                        local file = item.file
                        picker:close()
                        open_path_vsplit_at_win(file, place_window_opts)
                    end,

                    desc = "edit_vsplit confirm which window to split",
                }
                return vim.tbl_deep_extend("force", opts or {}, {
                    picker = {
                        actions = {
                            edit_vsplit_pick_win = edit_vsplit_pick_win,
                            edit_hsplit_pick_win = edit_hsplit_pick_win,
                            edit_pick_win = edit_pick_win,
                        },
                        win = {
                            input = {
                                keys = {
                                    ["<C-ENTER>"] = { "edit_pick_win", mode = { "n", "i" } },
                                    ["<C-s>"] = { "edit_hsplit_pick_win", mode = { "n", "i" } },
                                    ["<C-v>"] = { "edit_vsplit_pick_win", mode = { "n", "i" } },
                                },
                            },
                        },
                    },
                })
            end,
        },
        {
            "nvim-neo-tree/neo-tree.nvim",
            opts = function(_, opts)
                return vim.tbl_deep_extend("force", opts or {}, {
                    window = {
                        mappings = {
                            ["<C-ENTER>"] = {
                                function(state)
                                    local node = state.tree:get_node()
                                    if node == nil then
                                        vim.notify("Neotree failed to get node (was nil)", vim.log.levels.ERROR, nil)
                                        return
                                    end
                                    local path = node.path
                                    if path == nil then
                                        vim.notify(
                                            "Neotree failed to get node path (was nil)",
                                            vim.log.levels.ERROR,
                                            nil
                                        )
                                        return
                                    end
                                    open_path_over_win(path)
                                end,
                            },
                            ["s"] = {
                                function(state)
                                    local node = state.tree:get_node()
                                    if node == nil then
                                        vim.notify("Neotree failed to get node (was nil)", vim.log.levels.ERROR, nil)
                                        return
                                    end
                                    local path = node.path
                                    if path == nil then
                                        vim.notify(
                                            "Neotree failed to get node path (was nil)",
                                            vim.log.levels.ERROR,
                                            nil
                                        )
                                        return
                                    end
                                    open_path_hsplit_at_win(path)
                                end,
                            },
                            ["S"] = {
                                function(state)
                                    local node = state.tree:get_node()
                                    if node == nil then
                                        vim.notify("Neotree failed to get node (was nil)", vim.log.levels.ERROR, nil)
                                        return
                                    end
                                    local path = node.path
                                    if path == nil then
                                        vim.notify(
                                            "Neotree failed to get node path (was nil)",
                                            vim.log.levels.ERROR,
                                            nil
                                        )
                                        return
                                    end
                                    open_path_vsplit_at_win(path)
                                end,
                            },
                        },
                    },
                })
            end,
        },
    },
}

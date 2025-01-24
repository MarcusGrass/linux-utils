local M = {}

---comment
---@param custom_diff string | nil, if using a custom diff tool, path
---@param branch_diff boolean diffing a branch
---@param at_origin boolean diffing with origin
M.diff_file_picker = function(custom_diff, branch_diff, at_origin)
    local git = require("util.git")
    local diff_files = function()
        local base = git.git_base_directory()
        if base == nil then
            return
        end
        local files_iter = {}
        if branch_diff then
            files_iter = git.git_iter_diffed_default_branch_abs_path()
        else
            files_iter = git.git_iter_diffed_files_abs_path()
        end
        if files_iter == nil then
            return
        end
        local lines = {}
        for s in files_iter do
            table.insert(lines, base .. "/" .. s)
        end
        return lines
    end
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local prev = require("telescope.previewers")
    local buf_prev = require("telescope.previewers.buffer_previewer")
    local use_env = nil
    if custom_diff ~= nil then
        use_env = { ["GIT_EXTERNAL_DIFF"] = custom_diff }
    end

    pickers
        .new(nil, {
            prompt_title = "Changed files",
            finder = finders.new_dynamic({
                fn = diff_files,
            }),
            sorter = conf.generic_sorter(),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if vim.fn.filereadable(selection[1]) == 1 then
                        vim.cmd("e " .. selection[1])
                    end
                end)
                return true
            end,
            previewer = prev.new_termopen_previewer({
                title = "Difft preview",
                env = use_env,
                get_command = function(entry)
                    local merge_base = git.git_show_merge_base(branch_diff, at_origin)
                    return { "git", "diff", merge_base, entry.value }
                end,
                teardown = buf_prev.search_teardown,
            }),
        })
        :find()
end
return M

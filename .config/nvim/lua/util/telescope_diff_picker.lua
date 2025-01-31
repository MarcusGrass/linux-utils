local M = {}

---comment
---@param custom_diff string | nil, if using a custom diff tool, path
---@param branch_diff boolean diffing a branch
---@param at_origin boolean diffing with origin
M.snacks_diff_file_picker = function(custom_diff, branch_diff, at_origin)
    local git = require("util.git")
    local diff_files = function()
        local base = git.git_base_directory()
        if base == nil then
            return nil
        end
        local files_iter = {}
        if branch_diff then
            files_iter = git.git_iter_diffed_default_branch_abs_path()
        else
            files_iter = git.git_iter_diffed_files_abs_path()
        end
        local files = {}
        for s in files_iter do
            table.insert(files, base .. "/" .. s)
        end
        return files
    end
    local use_env = nil
    if custom_diff ~= nil then
        use_env = { ["GIT_EXTERNAL_DIFF"] = custom_diff }
    end
    local files = diff_files()
    return require("snacks").picker({
        finder = function()
            local items = {}
            if files == nil then
                return items
            end
            local idx = 0
            for _, file in pairs(files) do
                table.insert(items, {
                    idx = idx,
                    file = file,
                })
                idx = idx + 1
            end
            return items
        end,
        preview = function(ctx)
            local merge_base = git.git_show_merge_base(branch_diff, at_origin)
            local cmd = { "git", "diff", merge_base, ctx.item.file }
            require("snacks").picker.preview.cmd(cmd, ctx, { env = use_env })
        end,
    })
end
return M

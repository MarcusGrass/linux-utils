local M = {}
M.snack_file_diff_picker = function()
    local git = require("util.git")
    local file = require("util.file")
    local debug = require("util.debug")
    local cur_file = file.get_current_file()
    if cur_file == nil then
        return
    end
    vim.notify(string.format("File=%s", debug.dump(cur_file)))
    local commits = git.git_get_file_change_commits(cur_file)

    vim.notify(string.format("Commits=%s", debug.dump(commits)))
    -- local diff_files = function()
    --     local base = git.git_base_directory()
    --     if base == nil then
    --         return nil
    --     end
    --     local files_iter = {}
    --     if branch_diff then
    --         files_iter = git.git_iter_diffed_default_branch_abs_path()
    --     else
    --         files_iter = git.git_iter_diffed_files_abs_path()
    --     end
    --     local files = {}
    --     for s in files_iter do
    --         table.insert(files, base .. "/" .. s)
    --     end
    --     return files
    -- end
    -- local use_env = nil
    -- if custom_diff ~= nil then
    --     use_env = { ["GIT_EXTERNAL_DIFF"] = custom_diff }
    -- end
    -- for _, value in pairs(commits) do
    --     vim.notify(string.format("commit = %s", value))
    -- end
    -- local files = diff_files()
    -- require("snacks.picker.source.proc").proc({
    --     {},
    --     {
    --         cmd
    --     }
    -- })
    return require("snacks").picker({
        finder = function()
            local items = {}
            local idx = 1
            for _, commit in pairs(commits) do
                table.insert(items, {
                    idx = idx,
                    file = cur_file,
                    text = commit,
                })
                idx = idx + 1
            end
            return items
        end,
        format = function(item)
            local ret = {}
            ret[#ret + 1] = { item.text }
            return ret
        end,
        preview = function(ctx)
            local cmd = {
                "git",
                "--no-pager",
                "difftool",
                "-t",
                "difftastic",
                string.format("%s~", ctx.item.text),
                ctx.item.text,
                "--",
                ctx.item.file,
            }
            require("snacks").picker.preview.cmd(cmd, ctx, { env = nil })
        end,
        confirm = function(picker, item)
            picker:close()
            if item then
                vim.notify(string.format("Picked %s", item.text), vim.log.levels.INFO)
                vim.cmd(string.format(":DiffviewOpen %s^! -- %s", item.text, item.file))
            end
        end,
    })
end
return M

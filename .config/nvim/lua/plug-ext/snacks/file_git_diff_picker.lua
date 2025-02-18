local M = {}
M.snack_file_diff_picker = function()
    local git = require("util.git")
    local file = require("util.file")
    local cur_file = file.get_current_file()
    if cur_file == nil then
        return
    end
    local commit_data = git.git_get_file_change_commits(cur_file)
    if commit_data == nil then
        return
    end

    return require("snacks").picker({
        finder = function()
            local items = {}
            local idx = 1
            for _, commit in pairs(commit_data) do
                table.insert(items, {
                    idx = idx,
                    file = cur_file,
                    sha = commit.sha,
                    sha_short = commit.sha_short,
                    date = commit.date,
                    author = commit.author,
                    subject = commit.subject,
                })
                idx = idx + 1
            end
            return items
        end,
        format = function(item)
            local ret = {}
            ret[#ret + 1] = { item.date }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { item.sha_short }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { item.author }
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { item.subject }
            return ret
        end,
        preview = function(ctx)
            local cmd = {
                "git",
                "--no-pager",
                "difftool",
                "-t",
                "difftastic",
                string.format("%s~", ctx.item.sha),
                ctx.item.sha,
                "--",
                ctx.item.file,
            }
            require("snacks").picker.preview.cmd(cmd, ctx, { env = nil })
        end,
        confirm = function(picker, item)
            picker:close()
            if item then
                vim.cmd(string.format(":DiffviewOpen %s^! -- %s", item.sha, item.file))
            end
        end,
    })
end
return M

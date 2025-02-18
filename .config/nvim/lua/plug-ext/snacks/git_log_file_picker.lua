local M = {}
M.git_log_file_picker = function()
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
        format = function(item, picker)
            -- From the Snacks source https://github.com/folke/snacks.nvim/blob/41c4391/lua/snacks/picker/format.lua#L166
            local highlight = require("snacks.picker.util.highlight")
            local snacks_util = require("snacks.picker.util")
            local ret = {}
            ret[#ret + 1] = { picker.opts.icons.git.commit, "SnacksPickerGitCommit" }
            ret[#ret + 1] = { snacks_util.align(item.date, 13), "SnacksPickerGitDate" }
            ret[#ret + 1] = { snacks_util.align(item.sha, 7, { truncate = true }), "SnacksPickerGitCommit" }
            ret[#ret + 1] = { " " }
            local msg = item.subject ---@type string
            local type, scope, breaking, body = msg:match("^(%S+)(%(.-%))(!?):%s*(.*)$")
            if not type then
                type, breaking, body = msg:match("^(%S+)(!?):%s*(.*)$")
            end
            local msg_hl = "SnacksPickerGitMsg"
            if type and body then
                local dimmed = vim.tbl_contains({ "chore", "bot", "build", "ci", "style", "test" }, type)
                msg_hl = dimmed and "SnacksPickerDimmed" or "SnacksPickerGitMsg"
                ret[#ret + 1] = {
                    type,
                    breaking ~= "" and "SnacksPickerGitBreaking"
                        or dimmed and "SnacksPickerBold"
                        or "SnacksPickerGitType",
                }
                if scope and scope ~= "" then
                    ret[#ret + 1] = { scope, "SnacksPickerGitScope" }
                end
                if breaking ~= "" then
                    ret[#ret + 1] = { "!", "SnacksPickerGitBreaking" }
                end
                ret[#ret + 1] = { ":", "SnacksPickerDelim" }
                ret[#ret + 1] = { " " }
                msg = body
            end
            ret[#ret + 1] = { msg, msg_hl }
            highlight.markdown(ret)
            highlight.highlight(ret, {
                ["#%d+"] = "SnacksPickerGitIssue",
            })
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

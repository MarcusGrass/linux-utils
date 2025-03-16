local git_log_file_picker = function()
    local file = require("util.file")
    local git = require("main_config").git
    local cur_file = file.get_current_file()
    if cur_file == nil then
        return
    end
    local commit_data = git.get_file_change_commits(cur_file)
    if commit_data == nil then
        return
    end

    return require("snacks").picker({
        finder = function()
            local items = {}
            for k, commit in ipairs(commit_data) do
                table.insert(items, {
                    idx = k + 1,
                    file = cur_file,
                    sha = commit.sha,
                    sha_short = commit.sha_short,
                    date = commit.date,
                    author = commit.author,
                    subject = commit.subject,
                })
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
            ret[#ret + 1] = { snacks_util.align(item.author, 14, { truncate = true }), "SnacksPickerGitAuthor" }
            ret[#ret + 1] = { " " }
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

local snacks_diff_file_picker = function(custom_diff, branch_diff, at_origin)
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
            local idx = 1
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

local cargo_cmds = {
    {
        text = "format",
        cmd = ":botright terminal cargo fmt --all",
        preview = {
            text = "Run `cargo format --all`",
            ft = "markdown",
        },
    },
    {
        text = "clippy",
        cmd = ":botright terminal cargo clippy",
        preview = {
            text = "Run `cargo clippy`",
            ft = "markdown",
        },
    },
    {
        text = "test",
        cmd = ":botright terminal cargo test",
        preview = {
            text = "Run `cargo test`",
            ft = "markdown",
        },
    },
    {
        text = "check all",
        cmd = ":botright terminal cargo fmt --all && cargo clippy && cargo test",
        preview = {
            text = "Run `cargo fmt --all && cargo clippy && cargo test`",
            ft = "markdown",
        },
    },
}

local snacks_cargo_cmd_picker = function()
    return require("snacks").picker({
        name = "cargo_cmd",
        items = cargo_cmds,
        preview = "preview",
        format = "text",
        confirm = function(picker, item)
            picker:close()
            if item then
                vim.cmd(string.format("%s", item.cmd))
            end
        end,
        previewers = {},
    })
end

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = function(_, opts)
        local key = require("util.keymap")
        key.mapnfn("<leader>tdo", function()
            snacks_diff_file_picker("~/.local/bin/difft", true, false)
        end)
        key.mapnfn("<leader>tde", function()
            snacks_diff_file_picker("~/.local/bin/difft", false, false)
        end)
        key.mapnfn("<leader>tdu", function()
            snacks_diff_file_picker("~/.local/bin/difft", false, true)
        end)
        key.mapnfn("<leader>tgo", function()
            snacks_diff_file_picker(nil, true, false)
        end)
        key.mapnfn("<leader>tge", function()
            snacks_diff_file_picker(nil, false, false)
        end)
        key.mapnfn("<leader>tgu", function()
            snacks_diff_file_picker(nil, false, true)
        end)
        key.mapnfn("<leader>fc", function()
            git_log_file_picker()
        end)
        key.mapn("<leader>fr", ':lua Snacks.picker.pick("resume")<CR>')
        -- Open snacks grep (Ctrl+Shift+f)
        key.mapn("<C-S-f>", ':lua Snacks.picker.pick("grep")<CR>')

        -- Open snacks file finder
        key.mapn("<leader>ff", ':lua Snacks.picker.pick("files")<CR>')
        -- Open snacks git file finder (when there's a bunch of files in e.g. ./target), could restrict to cwd
        key.mapn("<leader>fg", ':lua Snacks.picker.pick("git_files")<CR>')
        -- Open snacks buffer finder
        key.mapn("<leader>fb", ':lua Snacks.picker.pick("buffers")<CR>')
        key.mapnfn("<leader>pc", function()
            snacks_cargo_cmd_picker()
        end)
        -- Toggle terminal
        key.mapn("<leader>gt", ":lua Snacks.terminal.toggle()<CR>")
        key.mapn("<C-S-t>", ":lua Snacks.terminal.toggle()<CR>")
        key.mapn("<C-c>", ":lua Snacks.bufdelete.delete()<CR>")
        key.mapn("<leader>bd", ":lua Snacks.bufdelete.other()<CR>")
        -- Picker search for word under cursor
        key.mapn("gs", ':lua Snacks.picker.pick("grep_word")<CR>')
        key.map("x", "gs", '<ESC>:lua Snacks.picker.pick("grep_word")<CR>')

        return vim.tbl_deep_extend("force", opts or {}, {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
            bigfile = { enabled = false },
            dashboard = {
                enabled = true,
                sections = {
                    { section = "header" },
                    { section = "keys", gap = 1, padding = 1 },
                    { section = "startup" },
                    {
                        pane = 2,
                        icon = " ",
                        key = "s",
                        title = "Sessions",
                        section = "session",
                        action = ":lua require('persistence').select()",
                        indent = 2,
                        padding = 1,
                    },
                    { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                    {
                        pane = 2,
                        icon = " ",
                        title = "Git Status",
                        section = "terminal",
                        enabled = function()
                            return require("snacks").git.get_root() ~= nil
                        end,
                        cmd = "git status --short --branch --renames",
                        height = 5,
                        padding = 1,
                        ttl = 5 * 60,
                        indent = 3,
                    },
                },
            },
            indent = { enabled = false },
            input = { enabled = true },
            picker = {
                enabled = true,
            },
            terminal = {
                enabled = true,
                win = {
                    wo = {
                        winbar = "",
                    },
                },
            },
            notifier = {
                enabled = true,
                timeout = 10000,
            },
            quickfile = { enabled = false },
            scroll = { enabled = false },
            statuscolumn = { enabled = false },
            words = { enabled = false },
            styles = {
                terminal = {
                    keys = {
                        term_normal = {
                            "<esc>",
                            function(self)
                                self.esc_timer = self.esc_timer or vim.uv.new_timer()
                                if self.esc_timer:is_active() then
                                    self.esc_timer:stop()
                                    vim.cmd("stopinsert")
                                else
                                    self.esc_timer:start(750, 0, function() end)
                                    return "<esc>"
                                end
                            end,
                            mode = "t",
                            expr = true,
                            desc = "Double escape to normal mode",
                        },
                    },
                },
                notification = {
                    wo = {
                        wrap = true,
                    },
                },
            },
        })
    end,
}

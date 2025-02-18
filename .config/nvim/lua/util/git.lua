local M = {}

local get_current_branch_cmd = "git --no-pager branch --show-current"

local string_manipulation = require("util.string_manipulation")
M.git_base_directory = function()
    local base = "git --no-pager rev-parse --show-toplevel"
    local base_cmd = io.popen(base)
    if base_cmd == nil then
        return
    end
    if type(base_cmd) == "string" then
        vim.notify("Failed to get git dir base", vim.log.levels.ERROR)
        return
    end
    local base_dir = string_manipulation.first_trimmed_line(base_cmd:read("*a"))
    if base_dir == nil then
        vim.notify("Failed to get git dir base, no output from git", vim.log.levels.ERROR)
    end
    return base_dir
end

M.git_iter_diffed_files_abs_path = function(at_origin)
    local cmd = nil
    if at_origin then
        cmd = string.format("git --no-pager diff --name-only $(git merge-base HEAD $(%s))", get_current_branch_cmd)
    else
        cmd =
            string.format("git --no-pager diff --name-only $(git merge-base origin/HEAD $(%s))", get_current_branch_cmd)
    end
    local handle = io.popen(cmd)
    if handle == nil then
        return
    end
    if type(handle) == "string" then
        vim.notify(string.format("Failed to git diff %s", handle), vim.log.levels.ERROR)
        return
    end
    local read = handle:read("*a")
    local it = string_manipulation.iter_string_lines(read)
    if it == nil then
        vim.notify("Failed to get git diff files iterator", vim.log.levels.ERROR)
    end
    return it
end

-- Could do this another way, but this doesn't sync with the remote
local get_default_branch_cmd = "git --no-pager symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'"
-- Need to sync the default branch for this to make sense
local last_shared_commit_with_default_brach =
    string.format("git --no-pager merge-base $(%s) $(%s)", get_default_branch_cmd, get_current_branch_cmd)

M.git_iter_diffed_default_branch_abs_path = function()
    local cmd = string.format("git --no-pager diff --name-only $(%s)", last_shared_commit_with_default_brach)
    local handle = io.popen(cmd)
    if handle == nil then
        return
    end
    if type(handle) == "string" then
        vim.notify(string.format("Failed to git diff %s", handle), vim.log.levels.ERROR)
        return
    end
    local read = handle:read("*a")
    local it = string_manipulation.iter_string_lines(read)
    if it == nil then
        vim.notify("Failed to get git diff files iterator", vim.log.levels.ERROR)
    end
    return it
end

M.git_show_merge_base = function(branch_diff, at_origin)
    local cmd = nil
    if branch_diff then
        if at_origin then
            cmd = string.format("git --no-pager merge-base origin/HEAD $(%s)", last_shared_commit_with_default_brach)
        else
            cmd = string.format("git --no-pager merge-base HEAD $(%s)", last_shared_commit_with_default_brach)
        end
    elseif at_origin then
        cmd = string.format("git --no-pager merge-base origin/HEAD $(%s)", get_current_branch_cmd)
    else
        cmd = string.format("git --no-pager merge-base HEAD $(%s)", get_current_branch_cmd)
    end
    local handle = io.popen(cmd)
    if handle == nil then
        return
    end
    if type(handle) == "string" then
        vim.notify(string.format("Failed too get merge-base %s", handle), vim.log.levels.ERROR)
        return
    end
    local read = handle:read("*a")
    return string_manipulation.first_trimmed_line(read)
end

local format_sep = "<|COMMIT-SEP-TOKEN|>"

M.git_get_file_change_commits = function(file_name)
    -- The format string for git %H, does not behave well with lua's string.format, pass %H through %s
    local cmd = string.format(
        'git --no-pager log --pretty="format:%s" -- %s',
        "%H" .. format_sep .. "%h" .. format_sep .. "[%cs]" .. format_sep .. "%an" .. format_sep .. "%s",
        file_name
    )
    local handle = io.popen(cmd)
    if handle == nil then
        vim.notify("Git local file diff returned nil handle on command", vim.log.levels.WARN)
        return
    end
    if type(handle) == "string" then
        vim.notify(string.format("Failed to run git diff on file_name=%s, output=%s", file_name, handle))
        return
    end
    local lines = handle:read("*a")
    local commits = {}
    for line in string_manipulation.iter_string_lines(lines) do
        local commit_data = string_manipulation.split_string_to_table(line, format_sep)
        table.insert(commits, {
            sha = commit_data[1],
            sha_short = commit_data[2],
            date = commit_data[3],
            author = commit_data[4],
            subject = commit_data[5],
        })
    end
    return commits
end
return M

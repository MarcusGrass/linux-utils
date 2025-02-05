local cmp = require("cmp")
local source = {}

function source:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function source:get_debug_name()
    return "Ollama local"
end

local job = require("plenary.job")

function DUMP(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. DUMP(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end
local running_proc = nil
function source:complete(ctx, callback)
    local max_lines = 10
    local cursor = ctx.context.cursor
    local cur_line = ctx.context.cursor_line
    -- properly handle utf8
    -- local cur_line_before = string.sub(cur_line, 1, cursor.col - 1)
    local cur_line_before = vim.fn.strpart(cur_line, 0, math.max(cursor.col - 1, 0), 1)

    -- properly handle utf8
    -- local cur_line_after = string.sub(cur_line, cursor.col) -- include current character
    local cur_line_after = vim.fn.strpart(cur_line, math.max(cursor.col - 1, 0), vim.fn.strdisplaywidth(cur_line), 1) -- include current character

    local lines_before = vim.api.nvim_buf_get_lines(0, math.max(0, cursor.line - max_lines), cursor.line, false)
    table.insert(lines_before, cur_line_before)
    local before = ""
    for _, line in pairs(lines_before) do
        before = before .. "\n" .. line
    end

    local lines_after = vim.api.nvim_buf_get_lines(0, cursor.line + 1, cursor.line + max_lines, false)
    table.insert(lines_after, 1, cur_line_after)
    local after = ""
    for _, line in pairs(lines_after) do
        after = after .. "\n" .. line
    end
    local args = { "--pre", before }
    if after ~= "" then
        after = after .. "\n"
        table.insert(args, "--post")
        table.insert(args, after)
    end
    local proc = job:new({
        command = "/home/gramar/.local/bin/ollama-client",
        args = args,
        on_exit = function(j, resp)
            vim.schedule(function()
                local items = {}
                local output = ""
                for _, line in pairs(j:result()) do
                    output = output .. line .. "\n"
                end
                local prefix = string.sub(ctx.context.cursor_before_line, ctx.offset)
                local result = prefix .. output
                table.insert(items, {
                    cmp = {
                        kind_hl_group = "CmpItemKind" .. "Ollama",
                        kind_text = "Ollama",
                    },
                    label = result,
                    documentation = {
                        kind = cmp.lsp.MarkupKind.Markdown,
                        value = "```" .. (vim.filetype.match({ buf = 0 }) or "") .. "\n" .. result .. "\n```",
                    },
                })
                if resp ~= 0 then
                    vim.notify(string.format("Got err='%s' code='%s'", output, resp))
                else
                    vim.notify(string.format("Got resp='%s' code='%s'", output, resp))
                end
                callback({
                    items = items,
                    isIncomplete = true,
                })
            end)
        end,
    }):start()
    if running_proc ~= nil then
        local handle = io.popen("kill " .. running_proc.pid)
        if handle ~= nil then
            handle:close()
        end
    end
    if proc ~= nil then
        vim.notify(string.format("Started completion: %s, pid=%d", tostring(proc), proc.pid))
    end

    running_proc = proc
end

function source:end_complete(data, ctx, callback)
    vim.notify("Ended completion", vim.log.levels.INFO)
end

local src = source:new()
cmp.register_source("cmp_ollama_local", src)
vim.notify("Registered localama")

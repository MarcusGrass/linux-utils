local M = {}

M.snacks_inlay_picker = function()
    local hints = M.inlay_analyze()
    local items = {}
    local idx = 0
    for _, hint in pairs(hints) do
        table.insert(items, {
            idx = idx,
            file = hint.uri,
            text = hint.ident,
            pos = { hint.start_line + 1, 1 },
        })
        idx = idx + 1
    end

    return require("snacks").picker({
        items = items,
        format = function(item)
            local ret = {}
            ret[#ret + 1] = { item.text }
            return ret
        end,
    })

end

local function string_starts_with(String, Start)
    return string.sub(String, 1, string.len(Start))==Start
end

M.inlay_analyze = function ()
    local cursor_pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
    -- Stupid lua 1-index
    local current_line = cursor_pos[1]
    local current_col = cursor_pos[2]
    -- Try to filter, lsp doesn't really care though
    local range = {
        start = { line = current_line, character = 0 },
        ["end"] = { line = current_line + 1, character = 0 }
    }
    local hints = vim.lsp.inlay_hint.get({bufnr = 0, range})
    local use_hints = {}
    local zero_indexed_line = current_line - 1
    -- Needs an offset
    local zero_indexed_col = current_col + 1
    for _, hint in pairs(hints) do
        local inlay = hint.inlay_hint
        if inlay == nil then
            goto continue
        end
        local labels = inlay.label
        if labels == nil then
            goto continue
        end
        if inlay.kind ~= nil and inlay.kind == 2 then
            goto continue
        end
        if inlay.position == nil then
            goto continue
        end
        if inlay.position.line ~= zero_indexed_line then
            goto continue
        end
        if inlay.position.character < zero_indexed_col then
            goto continue
        end
        -- Filter out non-table labels
        if type(labels) == "string" then
            goto continue
        end
        for _, label in pairs(labels) do
            local value = label.value;
            local location = label.location;
            if location == nil then
                goto skip
            end
            local uri = location.uri
            if uri == nil then
                goto skip
            end
            if not string_starts_with(uri, "file:///") then
                goto skip
            end
            local start_line = location.range.start.line
            local use_uri = string.sub(uri, string.len("file://") + 1)
            local data = ({
                ident = value,
                uri = use_uri,
                start_line = start_line,
            })
            table.insert(use_hints, data);
            ::skip::
        end
        ::continue::
    end

    return use_hints

end

return M


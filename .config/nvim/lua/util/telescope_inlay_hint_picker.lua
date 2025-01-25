local M = {}

M.inlay_picker = function()
    local hints = M.inlay_analyze()
    local lines = {}
    --- Todo: Relativize to crate over `src` starting from the right
    for _, hint in pairs(hints) do
        table.insert(lines, {
            path = hint.uri,

        })
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local previews = {}
    for _, hint in pairs(hints) do
        table.insert(previews, {
            path = hint.uri,
            lnum = hint.start_line,
            start = hint.start_line,
            finish = hint.start_line + 10,
        })
    end

    pickers
        .new(nil, {
            prompt_title = "Choose inlay hint",
            finder = finders.new_table {
                results = hints,
                entry_maker = function (entry)
                    return {
                        value = entry,
                        display = entry.ident,
                        ordinal = entry.ident,
                        path = entry.uri,
                        lnum = entry.start_line + 1,
                    }
                end
            },
            previewer = conf.qflist_previewer(previews),
            on_complete = {
                function(picker)
                    if picker.manager.linked_states.size == 1 then
                        actions.select_default(picker.prompt_bufnr)
                    end
                end
            }

        })
        :find()
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


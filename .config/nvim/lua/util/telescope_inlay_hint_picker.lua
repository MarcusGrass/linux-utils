local M = {}

M.inlay_picker = function()
    local hints = M.inlay_analyze()
    local hint_files = function ()
        local lines = {}
        --- Todo: Relativize to crate over `src` starting from the right
        for _, hint in pairs(hints) do
            table.insert(lines, hint.uri)
        end
        return lines
    end
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    -- local actions = require("telescope.actions")
    -- local prev = require("telescope.previewers")
    -- local buf_prev = require("telescope.previewers.buffer_previewer")
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
                        finder = finders.new_dynamic({
                        fn = hint_files,
            }),
            -- sorter = conf.generic_sorter(),
            -- attach_mappings = function(prompt_bufnr)
            --     actions.select_default:replace(function()
            --         actions.close(prompt_bufnr)
            --         local selection = action_state.get_selected_entry()
            --         if vim.fn.filereadable(selection[1]) == 1 then
            --             vim.cmd("e " .. selection[1])
            --         end
            --     end)
            --     return true
            -- end,
            previewer = require('telescope.config').values.qflist_previewer(previews),

        })
        :find()
end

local function string_starts_with(String, Start)
    return string.sub(String, 1, string.len(Start))==Start
end

M.inlay_analyze = function ()
    function dump(o)
       if type(o) == 'table' then
          local s = '{ '
          for k,v in pairs(o) do
             if type(k) ~= 'number' then k = '"'..k..'"' end
             s = s .. ''..k..': ' .. dump(v) .. ','
          end
          return s .. '} '
       else
          return tostring(o)
       end
    end
    local hints = vim.lsp.inlay_hint.get({bufnr = 0})
    local out = ""
    local use_hints = {}
    for _, hint in pairs(hints) do
        local inlay = hint.inlay_hint
        if inlay == nil then
            goto continue
        end
        local labels = inlay.label
        if labels == nil then
            goto continue
        end
        out = out ..  type(labels) .. '\n'
        if type(labels) == "string" then
            out = out ..  labels .. '\n'
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

    -- out = out ..  dump(use_hints) .. '\n'
    -- vim.notify(out, vim.log.levels.ERROR);
    return use_hints

end

return M


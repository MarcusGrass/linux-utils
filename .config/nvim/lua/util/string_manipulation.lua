local M = {}

M.iter_string_lines = function(s)
    return s:gmatch("[^\r\n]+")
end

M.first_trimmed_line = function(s)
    return s:match("[^\r\n]+")
end

-- Unbelievable lua doesn't have a string split
-- Ripped from the Roblox forum from 2017, https://devforum.roblox.com/t/lua-split-string-function/34402/9
-- With some rewrites for a bit more clarity
M.split_string_to_table = function(s, split)
    local sections = {}
    local search_from = 1
    while search_from <= #s do
        local pattern_start, pattern_end = s:find(split, search_from, true)
        if pattern_start == nil then
            break
        end
        table.insert(sections, s:sub(search_from, pattern_start - 1))
        search_from = pattern_end + 1
    end
    table.insert(sections, s:sub(search_from))
    return sections
end
return M

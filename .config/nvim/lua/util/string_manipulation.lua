local M = {}

M.iter_string_lines = function(s)
    return s:gmatch("[^\r\n]+")
end

M.first_trimmed_line = function(s)
    return s:match("[^\r\n]+")
end
return M

local M = {}
M.dump = function(o, depth)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            if depth and depth < 5 then
                s = s .. "[" .. k .. "] = " .. M.dump(v, depth + 1) .. ","
            else
                if not depth then
                    s = s .. "[" .. k .. "] = " .. M.dump(v, 1) .. ","
                end
                return s .. "} "
            end
        end
        return s .. "} "
    else
        return tostring(o)
    end
end
return M

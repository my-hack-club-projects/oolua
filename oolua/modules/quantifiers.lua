local function reduce(...)
    local f = nil
    local t = {}
    for _, v in ipairs({ ... }) do
        if type(v) == "table" then
            for _, vv in ipairs(v) do
                table.insert(t, vv)
            end
        elseif type(v) == "function" then
            f = v
        else
            table.insert(t, v)
        end
    end

    return t, f
end

function all(...)
    local t, f = reduce(...)

    if not f then
        f = function(v) return v == true end
    end

    for _, v in ipairs(t) do
        if not f(v) then
            return false
        end
    end

    return true
end

function any(...)
    local t, f = reduce(...)

    if not f then
        f = function(v) return v == true end
    end

    for _, v in ipairs(t) do
        if f(v) then
            return true
        end
    end

    return false
end

function none(...)
    return not any(...)
end

return {
    all = all,
    any = any,
    none = none,
}

local Table = {}

function Table:values()
    local values = {}

    for _, v in pairs(self) do
        table.insert(values, v)
    end

    return values
end

function Table:insert(index, value)
    table.insert(self, index, value)
end

function Table:append(...)
    for _, v in ipairs({ ... }) do
        table.insert(self, v)
    end
end

function Table:prepend(...)
    for i = select("#", ...), 1, -1 do
        table.insert(self, 1, select(i, ...))
    end
end

function Table:find(value)
    for i, v in ipairs(self) do
        if v == value then
            return i
        end
    end
end

function Table:contains(value)
    return self:find(value) ~= nil
end

function Table:removeAt(index)
    table.remove(self, index)
end

function Table:remove(value)
    local index = self:find(value)

    if index then
        self:removeAt(index)
    end
end

function Table:clear()
    for i = #self, 1, -1 do
        table.remove(self, i)
    end
end

function Table:copy()
    return { table.unpack(self) }
end

function Table:map(func)
    local new = {}

    for i, v in ipairs(self) do
        new[i] = func(v, i)
    end

    return new
end

function Table:filter(func)
    local new = {}

    for i, v in ipairs(self) do
        if func(v, i) then
            table.insert(new, v)
        end
    end

    return new
end

function Table:reduce(func, initial)
    local acc = initial

    for i, v in ipairs(self) do
        acc = func(acc, v, i)
    end

    return acc
end

function Table:__tostring()
    return "{ " .. table.concat(self, ", ") .. " }"
end

function Table:__inspect()
    return self:__tostring()
end

return function(t)
    setmetatable(t, {
        __index = function(self, key)
            if type(key) == "table" and key.__on_index then
                return rawget(self, key:__on_index())
            else
                return Table[key] or rawget(self, key)
            end
        end,
        __inspect_hide = true
    })

    return t
end

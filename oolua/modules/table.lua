-- local oo = require("modules.oo")

local Table = {}

function Table:append(...)
    for _, v in ipairs({ ... }) do
        table.insert(self, v)
    end
end

function Table:__tostring()
    return "{ " .. table.concat(self, ", ") .. " }"
end

function Table:__inspect()
    return self:__tostring()
end

return function(t)
    setmetatable(t, { __index = Table, __inspect_hide = true })

    return t
end

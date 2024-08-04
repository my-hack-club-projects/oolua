local oo = {}

function oo.class(name, ...)
    local proto = oo.aug({}, ...)
    proto.__index = proto
    proto.__name = name or "Class"
    proto.__parents = { ... }
    proto.__children = {}

    for _, parent in ipairs(proto.__parents) do
        table.insert(parent.__children, proto)
    end

    setmetatable(proto, {
        __call = function(cls, ...)
            return cls.new(...)
        end
    })


    function proto.new(...)
        local self = setmetatable({}, proto)

        if proto.init then
            self.init(self, ...)
        end
        return self
    end

    function proto:is(a)
        local function recurse(children)
            if not children then
                return false
            end

            for _, child in ipairs(children) do
                if child.__name == self.__name then
                    return true
                end
                if child.__children and recurse(child.__children) then
                    return true
                end
            end
            return false
        end

        if self.__name == a.__name then
            return true
        end

        return recurse(a.__children)
    end

    return proto
end

function oo.aug(target, ...)
    for _, t in ipairs({ ... }) do
        for k, v in pairs(t) do
            target[k] = v
        end
    end
    return target
end

return oo

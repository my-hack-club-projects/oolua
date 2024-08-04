local oo = {}

function oo.class(name, ...)
    local proto = oo.aug({}, ...)
    proto.__index = proto
    proto.__name = name or "Class"
    proto.__parents = { ... }

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
        local function recurse(parents)
            for _, parent in ipairs(parents) do
                if parent == a then
                    return true
                elseif recurse(parent.__parents) then
                    return true
                end
            end
            return false
        end

        if a == proto then
            return true
        end

        return recurse(self.__parents)
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

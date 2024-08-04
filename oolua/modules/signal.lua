local oo = require("modules.oo")

local listener = oo.class()

function listener.init(self, func, ...)
    self._reverse = nil
    self._once = false

    self.func = func
    self.args = { ... }
end

function listener:call(...)
    self.func(table.unpack(self.args), ...)
end

function listener:stop()
    self.func = nil
    self.args = nil

    if self._reverse then
        local index = nil
        for i, v in ipairs(self._reverse) do
            if v == self then
                index = i
                break
            end
        end
        table.remove(self._reverse, index)
    end
end

local signal = oo.class()

function signal.init(self)
    self.listeners = {}
end

function signal:listen(func, ...)
    local new = listener(func, ...)
    new._reverse = self.listeners
    table.insert(self.listeners, new)
    return new
end

function signal:once(func, ...)
    local new = listener(func, ...)
    new._reverse = self.listeners
    new._once = true
    table.insert(self.listeners, new)
    return new
end

function signal:dispatch(...)
    for _, listener in ipairs(self.listeners) do
        listener:call(...)
        if listener._once then
            listener:stop()
        end
    end
end

return signal

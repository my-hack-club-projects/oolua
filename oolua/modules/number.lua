local oo = require("modules.oo")

local Number = oo.class("Number")
Number.__inspect_hide = true

function Number.init(self, value)
    self.value = value
end

function Number:__tostring()
    return tostring(self.value)
end

function Number:__add(other)
    return Number(self.value + other.value)
end

function Number:__sub(other)
    return Number(self.value - other.value)
end

function Number:__mul(other)
    return Number(self.value * other.value)
end

function Number:__div(other)
    return Number(self.value / other.value)
end

function Number:__eq(other)
    return self.value == other.value
end

function Number:__lt(other)
    return self.value < other.value
end

function Number:__le(other)
    return self.value <= other.value
end

function Number:__unm()
    return Number(-self.value)
end

function Number:__inspect()
    return self:__tostring()
end

return Number

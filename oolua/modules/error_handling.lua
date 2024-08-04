local oo = require("modules.oo")
local error_handling = {}

error_handling.exception = oo.class("Exception")

function error_handling.exception.init(self, message)
    self.message = message
end

function error_handling.exception:__tostring()
    return self.__name .. ": " .. self.message
end

function error_handling.exception:__inspect()
    return self:__tostring()
end

local function exceptionNameFromMessage(message)
    return tostring(message):match("^([%w_]+):") or "Exception"
end

function error_handling.pcall(func)
    local chainable = {}
    local exception_functions = {}

    local function except(exception, excfunc)
        exception_functions[exception.__name] = excfunc

        return chainable
    end

    chainable.except = except
    chainable.run = function()
        local original_exception = ""
        local success, exception_name = xpcall(func, function(err)
            original_exception = err
            return exceptionNameFromMessage(err)
        end)

        if not success then
            if exception_functions[exception_name] then
                exception_functions[exception_name](original_exception)
            else
                error(original_exception)
            end
        end
    end

    return chainable
end

return error_handling

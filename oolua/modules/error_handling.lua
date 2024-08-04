local oo = require("modules.oo")
local error_handling = {}

error_handling.exception = oo.class("Exception")

function error_handling.exception.init(self, message)
    self.message = message
end

function error_handling.exception:__tostring()
    if self.message then
        return self.__name .. ": " .. self.message
    else
        return self.__name
    end
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

    chainable.except = function(exception, exfunc)
        if exfunc then
            exception_functions[exception()] = exfunc
        else
            exfunc = exception
            exception_functions[error_handling.exception()] = exfunc
        end

        return chainable
    end

    chainable.run = function()
        local exception_is_string = true
        local success, thrown_exception = xpcall(func, function(err)
            exception_is_string = type(err) == "string"

            return err
        end)

        if not success then
            for exception, f in pairs(exception_functions) do
                if exception_is_string and exceptionNameFromMessage(thrown_exception) == exception.__name then
                    f(error_handling.exception(thrown_exception))
                    return
                elseif thrown_exception:is(exception) then
                    f(thrown_exception)
                    return
                end
            end

            error(thrown_exception)
        end
    end

    return chainable
end

return error_handling

local inspect = require("modules.inspect")

local quantifiers = require("modules.quantifiers")
local error_handling = require("modules.error_handling")

return {
    oo = require("modules.oo"),
    inspect = inspect,
    signal = require("modules.signal"),

    pcall = error_handling.pcall,

    all = quantifiers.all,
    any = quantifiers.any,
    none = quantifiers.none,

    Table = require("modules.table"),
    Number = require("modules.number"),
    Exception = error_handling.exception,

    import = function(modules)
        return {
            from = function(path)
                local returns = {}
                local module = require(path)
                for _, exportName in ipairs(modules) do
                    if exportName == "__all" then
                        return table.unpack(module.exports)
                    end

                    assert(module.exports[exportName], "Module " .. exportName .. " not found in " .. path)

                    table.insert(returns, module.exports[exportName])
                end
                return table.unpack(returns)
            end
        }
    end,
    print = function(...)
        local new = {}
        for i, v in ipairs({ ... }) do
            new[i] = inspect(v)
        end
        print(table.unpack(new))
    end,
}

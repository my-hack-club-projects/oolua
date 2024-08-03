local inspect = require("modules.inspect")

return {
    oo = require("modules.oo"),
    inspect = inspect,
    import = function(modules)
        return {
            from = function(path)
                local returns = {}
                local module = require(path)
                for _, exportName in ipairs(modules) do
                    assert(module.exports[exportName], "Module " .. exportName .. " not found in " .. path)

                    table.insert(returns, module.exports[exportName])
                end
                return table.unpack(returns)
            end
        }
    end,
    print = function(...)
        local new = {}
        for i, v in { ... } do
            if type(v) == "table" then
                new[i] = inspect(v)
            else
                new[i] = tostring(v)
            end
        end
        print(new)
    end,
}

-- import a list of modules from one path

return function(modules)
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
end

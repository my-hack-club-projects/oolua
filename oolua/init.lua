local oo = require("oolua.oo")

local oolua = {}

local end_words = {
    "for", "while", "if", "function", "do"
}

function oolua.setup()
    package.path = package.path .. ";./?.oolua"
end

function oolua.compile(filepath)
    local file = io.open(filepath, "r")
    if not file then
        error("Could not open file " .. filepath)
    end

    local code = file:read("*all")
    file:close()

    local transformed_code = oolua.transform_code(code)

    local env = {
        oo = oo,
        import = require("oolua.import")
    }
    for k, v in pairs(_G) do
        env[k] = v
    end

    local func, err = load(transformed_code, "oolua", "t", env)
    if not func then
        error("Error compiling code: " .. err)
    end

    return func
end

function oolua.transform_code(code)
    local transformed = {}
    local in_class = false
    local class_name = nil
    local end_counter = 0

    for line in code:gmatch("[^\r\n]+") do
        if line:match("^%s*class%s+[%w_]+") then
            if in_class then
                error("Nested classes are not supported")
            end

            -- Entering a class definition
            in_class = true
            end_counter = 0
            class_name = line:match("^%s*class%s+([%w_]+)")
            local arguments = line:match("^%s*class%s+[%w_]+%s*%((.*)%)")

            table.insert(transformed, "local " .. class_name .. ";")
            table.insert(transformed, "do")
            table.insert(transformed, class_name .. " = oo.class(" .. arguments .. ")")
        elseif in_class and line:match("^%s*end%s*$") then
            -- Exiting a class definition
            if end_counter == 0 then
                in_class = false
                class_name = nil
            end

            table.insert(transformed, line)

            end_counter = end_counter - 1
        elseif in_class and class_name then
            -- Inside a class definition
            -- Anything that starts with 'static' is a class method/variable
            -- If it starts with 'local', it's a private method/variable
            -- If there are both, raise an error

            local function _find(t, v)
                for _, value in ipairs(t) do
                    if value == v then
                        return true
                    end
                end
                return false
            end

            local words = {}
            for word in line:gmatch("%S+") do
                table.insert(words, word)

                if _find(end_words, word) then
                    end_counter = end_counter + 1
                end
            end

            if words[1] == "static" then
                table.remove(words, 1)

                local isFunction = false
                if words[1] == "function" then
                    table.remove(words, 1)
                    isFunction = true
                end

                local remaining = table.concat(words, " ")

                if isFunction then
                    table.insert(transformed, "function " .. class_name .. "." .. remaining)
                else
                    table.insert(transformed, class_name .. "." .. remaining)
                end
            elseif words[1] == "local" then
                table.remove(words, 1)
                table.insert(transformed, line)
            elseif words[1] == "function" then
                table.remove(words, 1)

                local function_name = string.match(words[1], "([^%(]+)")
                local parameters_str = string.match(line, "%b()")
                local parameters_no_brackets = string.match(parameters_str, "%((.*)%)")
                local parameters_list = {} -- will split by commas, ignoring %s+
                for parameter in parameters_no_brackets:gmatch("[^%s,]+") do
                    table.insert(parameters_list, parameter)
                end
                table.remove(parameters_list, 1)
                local parameters = table.concat(parameters_list, ", ")
                table.insert(
                    transformed,
                    "function " .. class_name .. ":" .. function_name .. "(" .. (parameters or "") .. ")"
                )
            else
                table.insert(transformed, line)
            end
        else
            -- Non-class code
            table.insert(transformed, line)
        end
    end

    for i, line in ipairs(transformed) do
        transformed[i] = oolua.transform_imports(line)
    end

    return table.concat(transformed, "\n")
end

function oolua.transform_imports(line)
    local import = line:match("^%s*import%s+\"([%w_]+)\"%s+from%s+\"([%w_]+)\"")
    if import then
        local modules = {}
        local modules_str = {}
        local path = line:match("from%s+\"([%w_]+)\"")

        for module in line:gmatch("\"([%w_]+)\"") do
            if module == path then
                goto continue
            end

            table.insert(modules, module)
            table.insert(modules_str, "\"" .. module .. "\"")

            ::continue::
        end

        line = "local " ..
            table.concat(modules, ", ") ..
            " = import({ " .. table.concat(modules_str, ", ") .. " }).from('" .. path .. "')"
    end

    return line
end

return oolua

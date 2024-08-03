-- This program will read the lexer result, modify it and return the result for it to be re-constructed
--[[
Syntax rules:
- Cannot define a variable with the following:
    - import, class, static, oo
]]

local lexer = require("lexer")

local transformer = {}

transformer.reserved_keywords = {
    "import", "class", "static", "oo",
}
transformer.stack_incrementing_keywords = {
    "function", "if", "do", "class"
}

local function _find(t, v)
    for i, w in ipairs(t) do
        if w == v then
            return i
        end
    end
end

function transformer.transform(tokens)
    tokens = transformer.remove_unneeded(tokens) -- Creates a new table, so we don't need to worry about modifying the original table

    local result = {}
    local current_i = 0

    local in_class_block = false
    local class_name = ""
    local class_depth = 0
    local stack_depth = 0

    local function append(...)
        for _, token in ipairs({ ... }) do
            table.insert(result, token)
        end
    end

    local function next_token()
        if current_i >= #tokens then
            return nil
        end

        repeat
            current_i = current_i + 1

            if current_i > #tokens then
                return nil
            elseif tokens[current_i].type == "whitespace" then
                append(tokens[current_i])
            elseif _find({ "keyword", "ident" }, tokens[current_i].type) and _find(transformer.stack_incrementing_keywords, tokens[current_i].data) then
                stack_depth = stack_depth + 1
            elseif tokens[current_i].type == "keyword" and tokens[current_i].data == "end" then
                if stack_depth == class_depth and in_class_block then
                    in_class_block = false
                    class_depth = 0
                    class_name = ""
                    append(transformer.string_to_tokens("--- End of class block"))
                elseif stack_depth <= 0 then
                    error("Syntax error: unexpected 'end' keyword")
                end
                stack_depth = stack_depth - 1
            end
        until tokens[current_i].type ~= "whitespace"

        return tokens[current_i]
    end

    local function previous_token()
        if current_i <= 1 then
            return nil
        end

        repeat
            current_i = current_i - 1

            if current_i < 1 then
                return nil
            elseif tokens[current_i].type == "whitespace" then
                append(tokens[current_i])
            end
        until tokens[current_i].type ~= "whitespace"

        return tokens[current_i]
    end

    local function peek_token(offset)
        local i = current_i + (offset or 0)
        if i < 1 or i > #tokens then
            return nil
        elseif tokens[i].type == "whitespace" then
            return peek_token(offset + (offset < 0 and -1 or 1))
        else
            return tokens[i]
        end
    end

    while next_token() do
        local token = peek_token()
        local prev_token = peek_token(-1)

        -- Handle syntax errors
        if token.type == "ident" and prev_token and (prev_token.data == "local" or prev_token.data == "function") then
            if token.data == "import" or token.data == "class" or token.data == "static" or token.data == "oo" then
                error("Syntax error: attempting to define a variable with a reserved keyword")
            end
        end

        -- Count stack depth
        -- local yes = false
        -- for _, keyword in ipairs(transformer.stack_incrementing_keywords) do
        --     if (token.type == "keyword" or token.type == "ident") and token.data == keyword then
        --         stack_depth = stack_depth + 1
        --         yes = true
        --     end
        -- end

        -- if not yes and token.type == "keyword" and token.data == "end" then
        --     if stack_depth == 0 then
        --         error("Syntax error: unexpected 'end' keyword")
        --     elseif stack_depth == class_depth then
        --         in_class_block = false
        --         class_depth = 0
        --         class_name = ""
        --         append(transformer.string_to_tokens("--- End of class"))
        --     end

        --     stack_depth = stack_depth - 1
        -- end

        -- Parse import statement
        if token.type == "ident" and token.data == "import" then
            local modules = {}
            while next_token().type ~= "ident" do
                local t = peek_token()
                if t.type == "string" then
                    table.insert(modules, t.data)
                end
            end

            assert(peek_token().data == "from", "Syntax error: expected 'from' keyword after 'import'")
            assert(next_token().type == "string_start", "Syntax error: expected string after 'from' keyword")

            local path = next_token()
            assert(path.type == "string", "Syntax error: expected string after 'from' keyword")
            assert(next_token().type == "string_end", "Syntax error: expected string end after path")
            local modules_str = {}
            for i, module in ipairs(modules) do
                table.insert(modules_str, '"' .. module .. '"')
            end
            append(transformer.string_to_tokens("local " ..
                table.concat(modules, ", ") ..
                " = import(" .. table.concat(modules_str, ", ") .. ").from(\"" .. path.data .. "\")"))

            goto continue
        end

        -- Parse class statement
        if token.type == "ident" and token.data == "class" then
            local name = next_token()
            assert(name.type == "ident", "Syntax error: expected identifier after 'class' keyword")
            local bracket = next_token()
            assert(bracket.type == "symbol" and (bracket.data == "(" or bracket.data == "()"),
                "Syntax error: expected '(' after class name")
            assert(not in_class_block, "Syntax error: nested class definitions are not allowed")

            in_class_block = true
            class_name = name.data
            class_depth = stack_depth

            local inherits = {}
            if bracket.data ~= "()" then
                while next_token().data ~= ")" do
                    local t = peek_token()
                    if t.type == "ident" then
                        table.insert(inherits, t.data)
                    elseif t.type == "symbol" and t.data ~= "," then
                        error("Syntax error: unexpected symbol '" .. t.data .. "'")
                    end
                end
            end

            append(transformer.string_to_tokens("--- Start of class"))
            append(transformer.string_to_tokens("local " .. class_name .. "; do")) -- To make local stuff truly local
            append(transformer.string_to_tokens(
                name.data .. " = oo.class(" .. table.concat(inherits, ", ") .. ")"
            ))

            goto continue
        end

        -- Parse special statements inside class blocks
        if in_class_block and (stack_depth == class_depth or _find(transformer.stack_incrementing_keywords, token.data)) then
            -- Static variables and functions
            if token.type == "ident" and token.data == "static" then
                local name = next_token()
                assert(name.type == "ident" or name.data == "function",
                    "Syntax error: expected identifier or function declaration after 'static' keyword")

                if name.data == "function" then
                    local function_name = next_token()
                    assert(function_name.type == "ident",
                        "Syntax error: expected identifier after 'function' keyword")

                    append(transformer.string_to_tokens("function " .. class_name .. "." .. function_name.data))
                else
                    assert(next_token().type == "operator" and peek_token().data == "=",
                        "Syntax error: expected '=' after static variable name")

                    append(transformer.string_to_tokens(class_name .. "." .. name.data .. " = "))
                end

                goto continue
            end

            -- Instance functions
            if token.type == "keyword" and token.data == "function" and prev_token.data ~= "local" then
                local name = next_token()

                assert(name.type == "ident", "Syntax error: expected identifier after 'function' keyword")
                next_token() -- skip the opening bracket '('

                local first_param = next_token()
                local is_self = first_param.data == "self" and first_param.type == "ident"

                if is_self then
                    local next = peek_token(1)
                    if next.data == "," then
                        next_token()
                    end
                end

                append(transformer.string_to_tokens("function " ..
                    class_name .. ":" .. name.data .. "(" .. (is_self == false and first_param.data or "")))

                goto continue
            end
        end

        -- If nothing else, just append the token
        append(token)

        ::continue::
    end

    return result
end

function transformer.remove_unneeded(tokens)
    local result = {}

    for _, line in ipairs(tokens) do
        for i, token in ipairs(line) do
            if token.type ~= "comment" then
                local new = {
                    data = token.data,
                    posFirst = token.posFirst,
                    posLast = token.posLast,
                    posOnLine = i,
                    type = token.type,
                }

                table.insert(result, new)
            end
        end
    end

    return result
end

function transformer.string_to_tokens(str)
    local lines = lexer(str)
    local tokens = {}

    for _, line in ipairs(lines) do
        for i, token in ipairs(line) do
            token.posOnLine = i
            table.insert(tokens, token)
        end
    end

    return table.unpack(tokens)
end

return transformer.transform

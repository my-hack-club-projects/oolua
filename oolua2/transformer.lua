-- This program will read the lexer result, modify it and return the result for it to be re-constructed
-- Example lexer output:
-- { { {
--   data = "local",
--   posFirst = 1,
--   posLast = 5,
--   type = "keyword"
-- }, {
--   data = " ",
--   posFirst = 6,
--   posLast = 6,
--   type = "whitespace"
-- }, {
--   data = "x",
--   posFirst = 7,
--   posLast = 7,
--   type = "ident"
-- }, {
--   data = " ",
--   posFirst = 8,
--   posLast = 8,
--   type = "whitespace"
-- }, {
--   data = "=",
--   posFirst = 9,
--   posLast = 9,
--   type = "operator"
-- }, {
--   data = " ",
--   posFirst = 10,
--   posLast = 10,
--   type = "whitespace"
-- }, {
--   data = "1",
--   posFirst = 11,
--   posLast = 11,
--   type = "number"
-- } }, {}, { {
--   data = "local",
--   posFirst = 1,
--   posLast = 5,
--   type = "keyword"
-- }, {
--   data = " ",
--   posFirst = 6,
--   posLast = 6,
--   type = "whitespace"
-- }, {
--   data = "function",
--   posFirst = 7,
--   posLast = 14,
--   type = "keyword"
-- }, {
--   data = " ",
--   posFirst = 15,
--   posLast = 15,
--   type = "whitespace"
-- }, {
--   data = "f",
--   posFirst = 16,
--   posLast = 16,
--   type = "ident"
-- }, {
--   data = "()",
--   posFirst = 17,
--   posLast = 18,
--   type = "symbol"
-- } }, { {
--   data = "    ",
--   posFirst = 1,
--   posLast = 4,
--   type = "whitespace"
-- }, {
--   data = "x",
--   posFirst = 5,
--   posLast = 5,
--   type = "ident"
-- }, {
--   data = " ",
--   posFirst = 6,
--   posLast = 6,
--   type = "whitespace"
-- }, {
--   data = "=",
--   posFirst = 7,
--   posLast = 7,
--   type = "operator"
-- }, {
--   data = " ",
--   posFirst = 8,
--   posLast = 8,
--   type = "whitespace"
-- }, {
--   data = "x",
--   posFirst = 9,
--   posLast = 9,
--   type = "ident"
-- }, {
--   data = " ",
--   posFirst = 10,
--   posLast = 10,
--   type = "whitespace"
-- }, {
--   data = "+",
--   posFirst = 11,
--   posLast = 11,
--   type = "operator"
-- }, {
--   data = " ",
--   posFirst = 12,
--   posLast = 12,
--   type = "whitespace"
-- }, {
--   data = "1",
--   posFirst = 13,
--   posLast = 13,
--   type = "number"
-- } }, { {
--   data = "    ",
--   posFirst = 1,
--   posLast = 4,
--   type = "whitespace"
-- }, {
--   data = "return",
--   posFirst = 5,
--   posLast = 10,
--   type = "keyword"
-- }, {
--   data = " ",
--   posFirst = 11,
--   posLast = 11,
--   type = "whitespace"
-- }, {
--   data = "x",
--   posFirst = 12,
--   posLast = 12,
--   type = "ident"
-- } }, { {
--   data = "end",
--   posFirst = 1,
--   posLast = 3,
--   type = "keyword"
-- } }, {}, { {
--   data = "print",
--   posFirst = 1,
--   posLast = 5,
--   type = "ident"
-- }, {
--   data = "(",
--   posFirst = 6,
--   posLast = 6,
--   type = "symbol"
-- }, {
--   data = "f",
--   posFirst = 7,
--   posLast = 7,
--   type = "ident"
-- }, {
--   data = "())",
--   posFirst = 8,
--   posLast = 10,
--   type = "symbol"
-- }, {
--   data = " ",
--   posFirst = 11,
--   posLast = 11,
--   type = "whitespace"
-- }, {
--   data = "-- 2",
--   posFirst = 12,
--   posLast = 15,
--   type = "comment"
-- } }, {} }

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

function transformer.transform(tokens)
    tokens = transformer.remove_unneeded(tokens) -- Creates a new table, so we don't need to worry about modifying the original table

    local result = {}
    local current_i = 0

    local function next_token()
        if current_i >= #tokens then
            print("Ending")
            return nil
        end

        current_i = current_i + 1
        return tokens[current_i]
    end

    local function peek_token(offset)
        return tokens[current_i + (offset or 0)]
    end

    local function append(...)
        for _, token in ipairs({ ... }) do
            table.insert(result, token)
        end
    end

    while next_token() do
        local token = peek_token()
        local prev_token = peek_token(-1)

        -- Handle syntax errors
        if token.type == "ident" and (prev_token == "local" or prev_token == "function") then
            if token.data == "import" or token.data == "class" or token.data == "static" or token.data == "oo" then
                error("Syntax error: attempting to define a variable with a reserved keyword")
            end
        end

        -- Parse import statement
        if token.type == "ident" and token.data == "import" then
            print("Found import")
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

        ::continue::
    end

    return result
end

function transformer.remove_unneeded(tokens)
    local result = {}

    for _, line in ipairs(tokens) do
        for i, token in ipairs(line) do
            if token.type ~= "whitespace" and token.type ~= "comment" then
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

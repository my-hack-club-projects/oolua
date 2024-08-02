-- This program takes in the transformer result and reconstructs it back into a string.

return function(tokens)
    local result = ""

    for i, token in ipairs(tokens) do
        if token.posOnLine == 1 and result ~= "" then
            result = result .. "\n"
        end

        result = result .. token.data
    end

    return result
end

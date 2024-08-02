-- This program takes in the transformer result and reconstructs it back into a string.

return function(tokens)
    local result = ""
    local prev_token = nil

    for i, token in ipairs(tokens) do
        if token.posOnLine == 1 and result ~= "" then
            result = result .. "\n"
        end

        -- if prev_token and prev_token.type ~= "whitespace" and token.type ~= "whitespace" then
        --     result = result .. " "
        -- end

        result = result .. token.data
        prev_token = token
    end

    return result
end

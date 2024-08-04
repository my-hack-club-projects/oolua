-- This will later be a wrapper that handles errors, retrieves file contents, etc.
-- Will also act as a CLI for the program.
local inspect = require("modules.inspect")
local lexer, transformer, reconstructor = require("lexer"), require("transformer"), require("reconstructor")
local cli = require("cli")

local oolua = {}

function oolua.compile(input)
    local lex = lexer(input)
    local transformed = transformer(lex)
    local compiled = reconstructor(transformed)

    return compiled
end

function oolua.run(code)
    local injected = require("injected")
    local env = {}
    for k, v in pairs(_G) do
        env[k] = v
    end
    for k, v in pairs(injected) do
        env[k] = v
    end
    local f, err = load(code, "oolua", "t", env)
    if not f then
        print("Compilation error: " .. err)
        return
    end
    return f()
end

if #arg > 0 then
    return cli(arg, oolua)
else
    return oolua
end

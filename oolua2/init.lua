-- This will later be a wrapper that handles errors, retrieves file contents, etc.
-- Will also act as a CLI for the program.
local inspect = require("inspect")
local lexer, transformer, reconstructor = require("lexer"), require("transformer"), require("reconstructor")

local path = arg[1]
local file = io.open(path, "r")
local contents = file:read("*a")
file:close()

local lexer_result = lexer(contents)
local transformed = transformer(lexer_result)
local code = reconstructor(transformed)

print(inspect(transformed))
print(string.rep("-", 50))
print(code)

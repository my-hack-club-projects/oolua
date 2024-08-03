return function(arg, oolua)
    assert(#arg > 0, "No arguments were supplied!")
    local action = arg[1]

    if action == "compile" then
        local output_path = nil
        local input_path = nil
        local flag_index = nil
        for i, v in ipairs(arg) do
            if v == "-o" then
                flag_index = i
            end
        end
        assert(flag_index and #arg > flag_index, "No output path provided. Use -o <path>")
        output_path = arg[flag_index + 1]
        input_path = arg[#arg]
        assert(output_path ~= input_path, "The input path is the same as the output path! Make sure it is the last argument.")

        local file = io.open(input_path, "r")
        local input = file:read("*a")
        file:close()

        local compiled_code = oolua.compile(input)

        local output_file = io.open(output_path, "w")
        output_file:write(compiled_code)
        output_file:close()

        print("Compiled and wrote to " .. output_path)
    elseif action == "run" then
        assert(#arg > 1, "No input path provided! Make sure it is the last argument")
        local input_path = arg[#arg]
        local file = io.open(input_path, "r")
        local input = file:read("*a")
        file:close()

        local compiled_code = oolua.compile(input)
        oolua.run(compiled_code)
    end
end

local oolua = require("oolua")

oolua.setup()

path = arg[1]

oolua.compile(path)()

local oo = require 'oo'
local inspect = require 'inspect'

local class1 = oo.class('Class1')
local class2 = oo.class('Class2', class1)

print(inspect(class1))
print(inspect(class2))

print(class1:is(class2))
print(class2:is(class1))

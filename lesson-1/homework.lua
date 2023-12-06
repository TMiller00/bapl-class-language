local lpeg = require "lpeg"

local p = lpeg.P("hello")

print(lpeg.match(p, "hello world"))
print(lpeg.match(p, "hy world"))

local lpeg = require "lpeg"
local luaunit = require "luaunit"

local space = lpeg.S(" ") ^ 0
local digits = lpeg.R("09") ^ 1 * space
local op = lpeg.P("+") * space

local base = digits * (op * digits) ^ 1
local p = space * base ^ 1 * space

function TestPattern()
  luaunit.assertEquals(p:match("1 + 1"), 6)
  luaunit.assertEquals(p:match("10 + 22"), 8)
end

os.exit(luaunit.LuaUnit.run())

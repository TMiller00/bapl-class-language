local lpeg = require "lpeg"
local luaunit = require "luaunit"

local digits = lpeg.R("09") ^ 1
local op = lpeg.S("+")

local base = digits * (op * digits) ^ 0 * -1
local p = base ^ 1

function TestPattern()
  luaunit.assertEquals(p:match("12+13+25"), 9)
  luaunit.assertEquals(p:match("123+1345+25"), 12)
  luaunit.assertEquals(p:match("123+1345+"), nil)
end

os.exit(luaunit.LuaUnit.run())

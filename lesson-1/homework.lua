local lpeg = require "lpeg"
local luaunit = require "luaunit"

local space = lpeg.S(" \n\t") ^ 0
local numeral = (lpeg.S("+-") ^ -1 * lpeg.R("09") ^ 1 / tonumber) * space
local op = lpeg.S("+") * space

local function fold(lst)
  local acc = 0

  for i = 1, #lst do
    acc = acc + lst[i]
  end

  return acc
end

local p = space * lpeg.Ct(numeral * (op * numeral) ^ 0) / fold * -1

function TestPattern()
  luaunit.assertEquals(p:match("12 + 23 + 34 + 45 + 56"), 170)
  luaunit.assertEquals(p:match("123 + 456 + 789"), 1368)
  luaunit.assertEquals(p:match("123 + 456 +"), nil)

  luaunit.assertEquals(p:match("123 + -456 + 789"), 456)
  luaunit.assertEquals(p:match("+123 + -456 + +789"), 456)
  luaunit.assertEquals(p:match("+123 + -456 + +789 +"), nil)
end

os.exit(luaunit.LuaUnit.run())

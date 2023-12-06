local lpeg = require "lpeg"
local luaunit = require "luaunit"

local digits = lpeg.R("09") ^ 1
local op = lpeg.Cp() * lpeg.S("+")

local base = lpeg.C(digits) * op ^ -1
local p = base ^ 1

function TestPattern()
  local twelve, three, thirteen, six, twentyfive = p:match("12+13+25")
  luaunit.assertStrMatches(twelve, "12")
  luaunit.assertStrMatches(three, "3")
  luaunit.assertStrMatches(thirteen, "13")
  luaunit.assertStrMatches(six, "6")
  luaunit.assertStrMatches(twentyfive, "25")
end

os.exit(luaunit.LuaUnit.run())

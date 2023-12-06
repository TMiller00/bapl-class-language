local lpeg = require "lpeg"
local luaunit = require "luaunit"

local space = lpeg.S(" \n\t") ^ 0
local numeral = (lpeg.S("+-") ^ -1 * lpeg.R("09") ^ 1 / tonumber) * space
local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("*/%^")) * space

local OP = "(" * space
local CP = ")" * space

local function fold(lst)
  local acc = lst[1]

  for i = 2, #lst, 2 do
    if lst[i] == "+" then
      acc = acc + lst[i + 1]
    elseif lst[i] == "-" then
      acc = acc - lst[i + 1]
    elseif lst[i] == "*" then
      acc = acc * lst[i + 1]
    elseif lst[i] == "/" then
      acc = acc / lst[i + 1]
    elseif lst[i] == "%" then
      acc = acc % lst[i + 1]
    elseif lst[i] == "^" then
      acc = acc ^ lst[i + 1]
    else
      error("invalid character")
    end
  end

  return acc
end

local primary = lpeg.V "primary"
local term = lpeg.V "term"
local exp = lpeg.V "exp"

g = lpeg.P { "exp",
  primary = numeral + OP * exp * CP,
  term = space * lpeg.Ct(primary * (opM * primary) ^ 0) / fold,
  exp = space * lpeg.Ct(term * (opA * term) ^ 0) / fold,
} * -1

function TestSimplePattern()
  luaunit.assertEquals(g:match("2 * 2 + 6 * 10"), 64)
  luaunit.assertEquals(g:match("34 - 32 / 16"), 32)
  luaunit.assertEquals(g:match("123 + 456 +"), nil)
  luaunit.assertEquals(g:match("5 % 3 * 4"), 8)
  luaunit.assertEquals(g:match("4 ^ 4 / 2"), 128)
  luaunit.assertEquals(g:match("2 * (2 + 6) * 10"), 160)
end

os.exit(luaunit.LuaUnit.run())

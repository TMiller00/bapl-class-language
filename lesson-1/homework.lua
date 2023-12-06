local lpeg = require "lpeg"
local luaunit = require "luaunit"

local space = lpeg.S(" \n\t") ^ 0
local numeral = (lpeg.S("+-") ^ -1 * lpeg.R("09") ^ 1 / tonumber) * space
local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("*/%^")) * space

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

local term = space * lpeg.Ct(numeral * (opM * numeral) ^ 0) / fold
local sum = space * lpeg.Ct(term * (opA * term) ^ 0) / fold * -1

function TestSimplePattern()
  luaunit.assertEquals(sum:match("2 * 2 + 6 * 10"), 64)
  luaunit.assertEquals(sum:match("34 - 32 / 16"), 32)
  luaunit.assertEquals(sum:match("123 + 456 +"), nil)
  luaunit.assertEquals(sum:match("5 % 3 * 4"), 8)
  luaunit.assertEquals(sum:match("4 ^ 4 / 2"), 128)
end

os.exit(luaunit.LuaUnit.run())

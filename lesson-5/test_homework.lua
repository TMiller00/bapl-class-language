local luaunit = require "luaunit"
local Main = require "homework"
local Compiler = require "compiler"

TestSuite = {}

function TestSuite:tearDown()
  Compiler["code"] = {}
  Compiler["nvars"] = 0
  Compiler["vars"] = {}
end

function TestSuite:testIntegerLessThan()
  luaunit.assertEquals(Main("x = 2 < 5; return x"), 1)
end

function TestSuite:testIntegerGreaterThan()
  luaunit.assertEquals(Main("y = 7 > 10; return y"), 0)
end

function TestSuite:testIntegerEquality()
  luaunit.assertEquals(Main("z = 7 == 7; return z"), 1)
end

function TestSuite:testIntegerInequality()
  luaunit.assertEquals(Main("a = 5 != 6; return a"), 1)
end

function TestSuite:testIntegerLessThanOrEqual()
  luaunit.assertEquals(Main("c = 12 <= 11; return c"), 0)
end

function TestSuite:testIntegerGreaterThanOrEqual()
  luaunit.assertEquals(Main("b = 9 >= 8; return b"), 1)
end

function TestSuite:testIntegerDivisionByZero()
  luaunit.assertEquals(Main("x = 1 / 0; return x"), math.huge)
end

function TestSuite:testFloatAddition()
  luaunit.assertEquals(Main("x = 1.1 + .9; return x"), 2.0)
end

function TestSuite:testFloatAddition_2()
  luaunit.assertEquals(Main("x = 1. + 0.9; return x"), 1.9)
end

function TestSuite:testHexadecimal()
  luaunit.assertEquals(Main("x = 0x15; return x"), 21)
end

function TestSuite:testHexadecimalAddition()
  luaunit.assertEquals(Main("x = 0x15 + 0x16; return x"), 43)
end

function TestSuite:testHexadecimalDivision()
  luaunit.assertEquals(Main("x = 0x16 / 2; return x"), 11)
end

function TestSuite:testScientific()
  luaunit.assertEquals(Main("x = 12e3; return x"), 12000.0)
end

function TestSuite:testScientificWithDecimal()
  luaunit.assertEquals(Main("x = 1.2e3; return x"), 1200.0)
end

function TestSuite:testScientificWithNegativeExponent()
  luaunit.assertEquals(Main("x = 1e-1; return x"), 0.1)
end

function TestSuite:testScientificAddition()
  luaunit.assertEquals(Main("x = 1.2e3 + 3e2; return x"), 1500.0)
end

function TestSuite:testScientificAdditionWithNoLeadingInteger()
  luaunit.assertEquals(Main("x = .2e3 + 1e3; return x"), 1200)
end

function TestSuite:testIfStatementWithTrue()
  local condition = [[
    a = 5;
    if a { b = 6 };
    return b
  ]]

  luaunit.assertEquals(Main(condition), 6)
end

function TestSuite:testIfStatementWithFalse()
  local condition = [[
    a = 0;
    if a { b = 6 };
    return b
  ]]

  luaunit.assertEquals(Main(condition), nil)
end

function TestSuite:testIfElseStatementWithTrue()
  local condition = [[
    a = 1;
    if a {
      b = 6
    } else {
      b = 7
    };
    return b
  ]]

  luaunit.assertEquals(Main(condition), 6)
end

function TestSuite:testIfElseStatementWithFalse()
  local condition = [[
    a = 0;
    if a == 1 {
      b = 6
    } else {
      b = 7
    };
    return b
  ]]

  luaunit.assertEquals(Main(condition), 7)
end

function TestSuite:testIfElseIfStatementWithTrue()
  local condition = [[
    a = 1;
    if a == 0 {
      b = 6
    } elseif a == 1 {
      b = 7
    } else {
      b = 8
    };
    return b
  ]]

  luaunit.assertEquals(Main(condition), 7)
end

function TestSuite:testIfElseIfStatementWithFalse()
  local condition = [[
    a = 1;
    if a == 0 {
      b = 6
    } elseif a == 0 {
      b = 7
    } else {
      b = 8
    };
    return b
  ]]

  luaunit.assertEquals(Main(condition), 8)
end

function TestSuite:testWhile()
  local loop = [[
    n = 6;
    c = 1;

    while n {
      c = c * n;
      n = n - 1;
    };

    return c
    ]]

  luaunit.assertEquals(Main(loop), 720)
end

-- Logical operators
function TestSuite:testAndWithTrue()
  luaunit.assertEquals(Main("a = 4 and 5; return a"), 5)
end

function TestSuite:testAndWithFalse()
  luaunit.assertEquals(Main("a = 0 and 3; return a"), 0)
end

function TestSuite:testOrWithTrue()
  luaunit.assertEquals(Main("a = 0 or 10; return a"), 10)
end

function TestSuite:testOrWithFalse()
  luaunit.assertEquals(Main("a = 2 or 3; return a"), 2)
end

--[[
function TestStatements()
  luaunit.assertEquals(Main("e = 0 ^ 0; return e"), 1)
  luaunit.assertEquals(Main("j = 1 - 4 + -10 % 3; return j"), -1)
  luaunit.assertEquals(Main("k = 1 - -8 % 5; return k"), -1)
  luaunit.assertEquals(Main("l = 2 % -7 / -3; return l"), 1.6666666666666667)
  luaunit.assertEquals(Main("m = -5 % -2; return m"), -1)
  luaunit.assertEquals(Main("n = 1 % 4 ^ 8; return n"), 1)
  luaunit.assertEquals(Main("o = -3 * -10 * 4 % -7; return o"), -6)
  luaunit.assertEquals(Main("p = -10 - 6 + 7 % -9; return p"), -18)

  luaunit.assertEquals(Main("p = -(-1); return p"), 1)
  luaunit.assertEquals(Main("p = -(-1) + 1; return p"), 2)
  luaunit.assertEquals(Main("f = 1 ^ -5 - 6 % 6; return f"), 1.0)
  luaunit.assertEquals(Main("f = (-5) ^ (-2); return f"), 0.04)
  luaunit.assertEquals(Main("f = -5 ^ (-2); return f"), -0.04)
  -- luaunit.assertEquals(Main("g = 10 > 2 == 1"), { g = 1 })
end

function TestUnary()
  luaunit.assertEquals(Main("x = !(1 < 2); return x"), false)
  luaunit.assertEquals(Main("x = !(1 + 2); return x"), false)
  luaunit.assertEquals(Main("x = !2; return x"), false)
  -- luaunit.assertEquals(Main("x = -(1 < 2); return x"), 1)
end

--]]
os.exit(luaunit.LuaUnit.run())

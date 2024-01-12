local luaunit = require "luaunit"
local Main = require "homework"
local Compiler = require "compiler"

TestSuite = {}

function TestSuite:tearDown()
  Compiler["code"] = {}
  Compiler["nvars"] = 0
  Compiler["vars"] = {}
end

-- -- -- -- -- -- -- --
-- Binary Operations --
-- -- -- -- -- -- -- --

-- Arithemtic
-- -- Addition
-- -- -- Floats
function TestSuite:testFloatAddition()
  luaunit.assertEquals(Main("x = 1.1 + .9; return x"), 2.0)
end

function TestSuite:testFloatAddition_2()
  luaunit.assertEquals(Main("x = 1. + 0.9; return x"), 1.9)
end

-- -- -- Hexadecimals
function TestSuite:testHexadecimalAddition()
  luaunit.assertEquals(Main("x = 0x15 + 0x16; return x"), 43)
end

-- -- -- Scientific
function TestSuite:testScientificAddition()
  luaunit.assertEquals(Main("x = 1.2e3 + 3e2; return x"), 1500.0)
end

function TestSuite:testScientificAdditionWithNoLeadingInteger()
  luaunit.assertEquals(Main("x = .2e3 + 1e3; return x"), 1200)
end

-- -- Subtraction
-- -- -- Scientific
function TestSuite:testSubtractionScientific()
  luaunit.assertEquals(Main("x = 1e-1 - 0.1; return x"), 0.0)
end

-- -- Multiplication
-- -- -- Scientific
function TestSuite:testMultiplicationScientific()
  luaunit.assertEquals(Main("x = 12e3 * 2.; return x"), 24000.0)
end

-- -- Division
-- -- -- Integers
function TestSuite:testIntegerDivisionByZero()
  luaunit.assertEquals(Main("x = 1 / 0; return x"), math.huge)
end

-- -- -- Hexadecimal
function TestSuite:testHexadecimalDivision()
  luaunit.assertEquals(Main("x = 0x16 / 2; return x"), 11)
end

-- -- -- Scientific
function TestSuite:testDivisionScientific()
  luaunit.assertEquals(Main("x = 1.2e3 / 2; return x"), 600.0)
end

-- -- Exponent
-- -- -- Integers
function TestSuite:testExponentZero()
  luaunit.assertEquals(Main("e = 0 ^ 0; return e"), 1)
end

-- -- Modulo
-- -- -- Integers
function TestSuite:testModulo1()
  luaunit.assertEquals(Main("m = -5 % -2; return m"), -1)
end

-- -- Less Than
-- -- -- Integers
function TestSuite:testIntegerLessThan()
  luaunit.assertEquals(Main("x = 2 < 5; return x"), 1)
end

-- -- Greater Than
-- -- -- Integers
function TestSuite:testIntegerGreaterThan()
  luaunit.assertEquals(Main("y = 7 > 10; return y"), 0)
end

-- -- Less Than Or Equal
-- -- -- Integers
function TestSuite:testIntegerLessThanOrEqual()
  luaunit.assertEquals(Main("c = 12 <= 11; return c"), 0)
end

-- -- Greater Than Less Or Equal
-- -- -- Integers
function TestSuite:testIntegerGreaterThanOrEqual()
  luaunit.assertEquals(Main("b = 9 >= 8; return b"), 1)
end

-- -- Equals
-- -- -- Integers
function TestSuite:testIntegerEquality()
  luaunit.assertEquals(Main("z = 7 == 7; return z"), 1)
end

-- -- Not Equals
-- -- -- Integers
function TestSuite:testIntegerInequality()
  luaunit.assertEquals(Main("a = 5 != 6; return a"), 1)
end

-- Logical
-- -- And
-- -- -- Integers
function TestSuite:testAndWithTrue()
  luaunit.assertEquals(Main("a = 4 and 5; return a"), 5)
end

function TestSuite:testAndWithFalse()
  luaunit.assertEquals(Main("a = 0 and 3; return a"), 0)
end

-- -- -- Or
function TestSuite:testOrWithTrue()
  luaunit.assertEquals(Main("a = 0 or 10; return a"), 10)
end

function TestSuite:testOrWithFalse()
  luaunit.assertEquals(Main("a = 2 or 3; return a"), 2)
end

-- -- -- -- -- --
-- Statements  --
-- -- -- -- -- --

-- -- Arithemtic
function TestSuite:testArithemticExpressions1()
  luaunit.assertEquals(Main("j = 1 - 4 + -10 % 3; return j"), -1)
end

function TestSuite:testArithemticExpressions2()
  luaunit.assertEquals(Main("k = 1 - -8 % 5; return k"), -1)
end

function TestSuite:testArithemticExpressions3()
  luaunit.assertEquals(Main("l = 2 % -7 / -3; return l"), 1.6666666666666667)
end

-- -- If
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

-- -- If Else
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

-- -- If Else If
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

-- -- While
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

function TestSuite:testWhileWithIfStatement()
  local loop = [[
    n = 10;
    c = 1;

    while n {
      if n % 2 == 0 {
        c = c * n;
      };
      n = n - 1;
    };

    return c
    ]]

  luaunit.assertEquals(Main(loop), 3840)
end

-- -- -- -- --
-- Arrays   --
-- -- -- -- --

function TestSuite:testArray()
  local code = [[
    a = new [10];
    a[5] = 23;
    return a[5]
  ]]

  luaunit.assertEquals(Main(code), 23)
end

function TestSuite:testArrayIndexOutOfRange()
  local code = [[
    a = new [10];
    a[11] = 23;
    return a[5]
  ]]

  local function callMain()
    return Main(code)
  end

  luaunit.assertErrorMsgContains("index out of range", callMain)
end

function TestSuite:testArrayIndexOutOfRange2()
  local code = [[
    a = new [10];
    a[5] = 23;
    return a[11]
  ]]

  local function callMain()
    return Main(code)
  end

  luaunit.assertErrorMsgContains("index out of range", callMain)
end

function TestSuite:testMultidimensionalArrays()
  local code = [[
    a = new [1];
    b = new [2];
    c = new [3];
    c[1] = 4;
    b[1] = c;
    a[1] = b;
    return a[1][1][1]
  ]]

  luaunit.assertEquals(Main(code), 4)
end

--[[
function TestStatements()
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

local luaunit = require "luaunit"
local Main = require "homework"

function TestComparison()
  luaunit.assertEquals(Main("x = 2 < 5; return x"), 1)
  luaunit.assertEquals(Main("y = 7 > 10; return y"), 0)
  luaunit.assertEquals(Main("z = 3 + 4 == 7; return z"), 1)
  luaunit.assertEquals(Main("a = 5 != 6; return a"), 1)
  luaunit.assertEquals(Main("b = 9 >= 8; return b"), 1)
  luaunit.assertEquals(Main("c = 12 <= 11; return c"), 0)
  luaunit.assertEquals(Main("d = 20 + 30 != 50; return d"), 0)
  luaunit.assertEquals(Main("e = 15 > 15; return e"), 0)
  luaunit.assertEquals(Main("f = 3 * 4 == 12; return f"), 1)
  luaunit.assertEquals(Main("g = 10 / 2 == 5; return g"), 1)
end

function TestStatements()
  luaunit.assertEquals(Main("x = 1 / 0; return x"), math.huge)
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

os.exit(luaunit.LuaUnit.run())

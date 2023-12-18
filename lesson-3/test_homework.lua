local luaunit = require "luaunit"
local Main = require "homework"

function TestComparison()
  luaunit.assertEquals(Main("x = 2 < 5"), { x = 1 })
  luaunit.assertEquals(Main("y = 7 > 10"), { y = 0 })
  luaunit.assertEquals(Main("z = 3 + 4 == 7"), { z = 1 })
  luaunit.assertEquals(Main("a = 5 != 6"), { a = 1 })
  luaunit.assertEquals(Main("b = 9 >= 8"), { b = 1 })
  luaunit.assertEquals(Main("c = 12 <= 11"), { c = 0 })
  luaunit.assertEquals(Main("d = 20 + 30 != 50"), { d = 0 })
  luaunit.assertEquals(Main("e = 15 > 15"), { e = 0 })
  luaunit.assertEquals(Main("f = 3 * 4 == 12"), { f = 1 })
  luaunit.assertEquals(Main("g = 10 / 2 == 5"), { g = 1 })
end

function TestStatements()
  luaunit.assertEquals(Main("x = 1 / 0"), { x = 1 / 0 })
  luaunit.assertEquals(Main("e = 0 ^ 0"), { e = 1 })
  luaunit.assertEquals(Main("j = 1 - 4 + -10 % 3"), { j = -1 })
  luaunit.assertEquals(Main("k = 1 - -8 % 5"), { k = -1 })
  luaunit.assertEquals(Main("l = 2 % -7 / -3"), { l = 1.6666666666666667 })
  luaunit.assertEquals(Main("m = -5 % -2"), { m = -1 })
  luaunit.assertEquals(Main("n = 1 % 4 ^ 8"), { n = 1 })
  luaunit.assertEquals(Main("o = -3 * -10 * 4 % -7"), { o = -6 })
  luaunit.assertEquals(Main("p = -10 - 6 + 7 % -9"), { p = -18 })
  luaunit.assertEquals(Main("f = 1 ^ -5 - 6 % 6"), { f = 1.0 })
  -- luaunit.assertEquals(Main("g = 10 > 2 == 1"), { g = 1 })
end

os.exit(luaunit.LuaUnit.run())

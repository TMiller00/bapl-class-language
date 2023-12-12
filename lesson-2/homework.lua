local lpeg = require "lpeg"
local luaunit = require "luaunit"

-- Front End --------------------------------------

local space = lpeg.S(" \t\n") ^ 0
local hexLeader = "0" * (lpeg.P("x") + lpeg.P("X"))
local hexContent = (lpeg.R("af", "AF") + lpeg.R("09")) ^ -6

local hexadecimal = hexLeader * hexContent * -1 * space
local numeral = lpeg.R("09") ^ 1 * -1 * space

local function node(num)
  return { tag = "number", val = tonumber(num) }
end

local numbers = space * (hexadecimal + numeral) / node

local function parse(input)
  return numbers:match(input)
end

-- Back End ---------------------------------------

local function compile(ast)
  if ast.tag == "number" then
    return { "push", ast.val }
  end
end

-- Execution --------------------------------------

local function run(code, stack)
  local pc = 1
  local top = 0

  while pc < #code do
    if code[pc] == "push" then
      pc = pc + 1
      top = top + 1
      stack[top] = code[pc]
    else
      error("unknown instruction")
    end

    pc = pc + 1
  end
end

---------------------------------------------------

local function testNumbers(input)
  local stack = {}
  local ast = parse(input)
  local code = compile(ast)
  run(code, stack)

  return stack[1]
end

function TestNumbers()
  luaunit.assertEquals(testNumbers("5"), 5)
  luaunit.assertEquals(testNumbers("10"), 10)
  luaunit.assertEquals(testNumbers("0x1"), 1)
  luaunit.assertEquals(testNumbers("0x2A"), 42)
  luaunit.assertEquals(testNumbers("0x3abc"), 15036)
  luaunit.assertEquals(testNumbers("0x4ABCD"), 306125)
  luaunit.assertEquals(testNumbers("0x5abcde"), 5946590)
  luaunit.assertEquals(testNumbers("0x6F4F3F"), 7294783)
  luaunit.assertEquals(testNumbers("    0X111"), 273)
end

os.exit(luaunit.LuaUnit.run())

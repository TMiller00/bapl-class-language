local lpeg = require "lpeg"
local luaunit = require "luaunit"

-- Front End
-- Utilities
local space = lpeg.S(" \t\n") ^ 0
local negative = lpeg.S("-") ^ -1
local digits = lpeg.R("09") ^ 1

-- Comparisons
local comparison =
    lpeg.P("==") +
    lpeg.P(">=") +
    lpeg.P("<=") +
    lpeg.P(">") +
    lpeg.P("<") +
    lpeg.P("!=")

-- Hexadecimals
local hexLeader = "0" * (lpeg.P("x") + lpeg.P("X"))
local hexContent = (lpeg.R("af", "AF") + lpeg.R("09")) ^ -6
local hexadecimal = hexLeader * hexContent * space

-- Numbers
local integers = negative * digits * -lpeg.S("Xx")
local floats = negative * digits ^ -1 * "." * digits
local scientific = negative * digits * lpeg.S("Ee") * digits

local function node(num)
  return { tag = "number", val = tonumber(num) }
end

local numbers = (hexadecimal + floats + scientific + integers) * space / node

-- Parenthesis
local OP = "(" * space
local CP = ")" * space

-- Operators
local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("%*/")) * space
local opP = lpeg.C(lpeg.S("^")) * space
local opC = lpeg.C(comparison) * space

-- "Grammar"
local function foldBin(lst)
  local tree = lst[1]

  for i = 2, #lst, 2 do
    tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
  end

  return tree
end

local value = lpeg.V("value")
local power = lpeg.V("power")
local product = lpeg.V("product")
local sum = lpeg.V("sum")
local comp = lpeg.V("comp")

g = space * lpeg.P { "comp",
  value = numbers + OP * comp * CP,
  power = space * lpeg.Ct(value * (opP * value) ^ 0) / foldBin,
  product = space * lpeg.Ct(power * (opM * power) ^ 0) / foldBin,
  sum = space * lpeg.Ct(product * (opA * product) ^ 0) / foldBin,
  comp = lpeg.Ct(sum * (opC * sum) ^ 0) / foldBin
} * -1

local function parse(input)
  return g:match(input)
end

-- Back End

local function addCode(state, op)
  local code = state.code
  code[#code + 1] = op
end

local ops = {
  ["+"] = "add",
  ["-"] = "sub",
  ["*"] = "mul",
  ["/"] = "div",
  ["%"] = "mod",
  ["^"] = "pow",
  [">"] = "gt",
  ["<"] = "lt",
  [">="] = "gte",
  ["<="] = "lte",
  ["=="] = "eq",
  ["!="] = "neq"
}

local function codeExp(state, ast)
  if ast.tag == "number" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "binop" then
    codeExp(state, ast.e1)
    codeExp(state, ast.e2)
    addCode(state, ops[ast.op])
  else
    error("invalid tree")
  end
end

local function compile(ast)
  local state = { code = {} }
  codeExp(state, ast)
  return state.code
end

-- Execution

local function run(code, stack)
  local pc = 1
  local top = 0

  while pc <= #code do
    if code[pc] == "push" then
      pc = pc + 1
      top = top + 1
      stack[top] = code[pc]
    elseif code[pc] == "add" then
      stack[top - 1] = stack[top - 1] + stack[top]
      top = top - 1
    elseif code[pc] == "sub" then
      stack[top - 1] = stack[top - 1] - stack[top]
      top = top - 1
    elseif code[pc] == "mul" then
      stack[top - 1] = stack[top - 1] * stack[top]
      top = top - 1
    elseif code[pc] == "div" then
      stack[top - 1] = stack[top - 1] / stack[top]
      top = top - 1
    elseif code[pc] == "mod" then
      stack[top - 1] = stack[top - 1] % stack[top]
      top = top - 1
    elseif code[pc] == "pow" then
      stack[top - 1] = stack[top - 1] ^ stack[top]
      top = top - 1
    elseif code[pc] == "gt" then
      stack[top - 1] = (stack[top - 1] > stack[top]) and 1 or 0
      top = top - 1
    elseif code[pc] == "lt" then
      stack[top - 1] = (stack[top - 1] < stack[top]) and 1 or 0
      top = top - 1
    elseif code[pc] == "gte" then
      stack[top - 1] = (stack[top - 1] >= stack[top]) and 1 or 0
      top = top - 1
    elseif code[pc] == "lte" then
      stack[top - 1] = (stack[top - 1] <= stack[top]) and 1 or 0
      top = top - 1
    elseif code[pc] == "eq" then
      stack[top - 1] = (stack[top - 1] == stack[top]) and 1 or 0
      top = top - 1
    elseif code[pc] == "neq" then
      stack[top - 1] = (stack[top - 1] ~= stack[top]) and 1 or 0
      top = top - 1
    else
      error("unknown instruction")
    end

    pc = pc + 1
  end
end

-- Tests

local function testNumbers(input)
  local stack = {}
  local ast = parse(input)
  local code = compile(ast)
  run(code, stack)

  return stack[1]
end

function TestNumbers()
  luaunit.assertEquals(testNumbers("  25  "), 25)
  luaunit.assertEquals(testNumbers("25.0"), 25)
  luaunit.assertEquals(testNumbers(".5"), 0.5)
  luaunit.assertEquals(testNumbers("-0.5"), -0.5)
  luaunit.assertEquals(testNumbers("-.5"), -0.5)
  luaunit.assertEquals(testNumbers("123e12"), 1.23e+14)

  luaunit.assertEquals(testNumbers("5 * 5"), 25)
  luaunit.assertEquals(testNumbers("4 / 2"), 2.0)
  luaunit.assertEquals(testNumbers("3 * 4 / 2"), 6.0)

  luaunit.assertEquals(testNumbers("0x5 * 0x5"), 25)
  luaunit.assertEquals(testNumbers("0x4 / 0x2"), 2.0)
  luaunit.assertEquals(testNumbers("0x3 * 0x4 / 0x2"), 6.0)

  luaunit.assertEquals(testNumbers("7 + 5 * 5"), 32)
  luaunit.assertEquals(testNumbers("2 - 4 / 2"), 0.0)
  luaunit.assertEquals(testNumbers("1 - 3 + 3 * 4 / 2"), 4.0)

  luaunit.assertEquals(testNumbers("5 % 2 * 4"), 4)
  luaunit.assertEquals(testNumbers("4 % 2 / 2"), 0.0)

  luaunit.assertEquals(testNumbers("4 * 5 ^ 2"), 100)
  luaunit.assertEquals(testNumbers("28 + 10 ^ 2"), 128)

  luaunit.assertEquals(testNumbers("(15 + 10) * 2"), 50)
  luaunit.assertEquals(testNumbers("(1 + 2) ^ 2 % 3"), 0)
  luaunit.assertEquals(testNumbers("(1 + 2) ^ 2 % 3"), 0)

  luaunit.assertEquals(testNumbers("1 + -1"), 0)
  luaunit.assertEquals(testNumbers("5 * -2"), -10)
  luaunit.assertEquals(testNumbers("5 / -2"), -2.5)

  luaunit.assertEquals(testNumbers("1 > 0"), 1)
  luaunit.assertEquals(testNumbers("(1 + 1) > (2 + 2)"), 0)

  luaunit.assertEquals(testNumbers("1 < 0"), 0)
  luaunit.assertEquals(testNumbers("(1 / 1) < (2 * 2)"), 1)

  luaunit.assertEquals(testNumbers("1 < 0"), 0)
  luaunit.assertEquals(testNumbers("(1 / 1) < (2 * 2)"), 1)

  luaunit.assertEquals(testNumbers("1 >= 0"), 1)
  luaunit.assertEquals(testNumbers("1 >= 1"), 1)
  luaunit.assertEquals(testNumbers("(5 - 3) >= (2 / 2)"), 1)

  luaunit.assertEquals(testNumbers("1 <= 0"), 0)
  luaunit.assertEquals(testNumbers("1 <= 1"), 1)
  luaunit.assertEquals(testNumbers("(2 / 2) <= (5 - 3)"), 1)

  luaunit.assertEquals(testNumbers("1 == 0"), 0)
  luaunit.assertEquals(testNumbers("1 == 1"), 1)
  luaunit.assertEquals(testNumbers("(2 / 2) == (1 * 1)"), 1)

  luaunit.assertEquals(testNumbers("1 != 0"), 1)
  luaunit.assertEquals(testNumbers("1 != 1"), 0)
  luaunit.assertEquals(testNumbers("(5 / 2) != (6 * 1)"), 1)

  luaunit.assertEquals(testNumbers("1 != 0.1"), 1)
  luaunit.assertEquals(testNumbers("1 + 1.1"), 2.1)
  luaunit.assertEquals(testNumbers("2.5 / 2"), 1.25)

  luaunit.assertEquals(testNumbers("((5 / 2) != (6 * 1)) + 1"), 2)
end

os.exit(luaunit.LuaUnit.run())

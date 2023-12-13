local lpeg = require "lpeg"
local luaunit = require "luaunit"

-- Front End
-- Spaces
local space = lpeg.S(" \t\n") ^ 0

-- Hexadecimals
local hexLeader = "0" * (lpeg.P("x") + lpeg.P("X"))
local hexContent = (lpeg.R("af", "AF") + lpeg.R("09")) ^ -6
local hexadecimal = hexLeader * hexContent * space

-- Integers
local numeral = lpeg.R("09") ^ 1 * -lpeg.S("Xx") * space

-- All Numbers
local function node(num)
  return { tag = "number", val = tonumber(num) }
end

local numbers = (hexadecimal + numeral) / node

-- Operators
local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("%*/")) * space
local opP = lpeg.C(lpeg.S("^")) * space

-- "Grammar"
local function foldBin(lst)
  local tree = lst[1]

  for i = 2, #lst, 2 do
    tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
  end

  return tree
end

local power = space * lpeg.Ct(numbers * (opP * numbers) ^ 0) / foldBin
local term = space * lpeg.Ct(power * (opM * power) ^ 0) / foldBin
local exp = space * lpeg.Ct(term * (opA * term) ^ 0) / foldBin

local function parse(input)
  return exp:match(input)
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
  ["^"] = "pow"
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
end

os.exit(luaunit.LuaUnit.run())

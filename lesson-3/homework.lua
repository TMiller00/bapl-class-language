local lpeg = require "lpeg"
local pt = require "pt"

-- Front End

-- AST Nodes
local function nodeAssign(id, exp)
  if exp then
    return { tag = "assignment", id = id, exp = exp }
  else
    return { tag = "empty_statement" }
  end
end

local function nodeNum(num)
  return { tag = "number", val = tonumber(num) }
end

local function nodeSequence(st1, st2)
  if st2 then
    return { tag = "sequence", st1 = st1, st2 = st2 }
  else
    return st1
  end
end

local function nodeVar(var)
  return { tag = "variable", var = var }
end

-- Utilities
local space = lpeg.S(" \t\n") ^ 0

local alpha = lpeg.R("AZ", "az")
local digit = lpeg.R("09")
local negative = lpeg.S("-") ^ -1
local underscore = lpeg.S("_")

local alphanum = alpha + digit + underscore
local numeral = digit ^ 1

local Assgn = "=" * space
local SC = ";" * space

-- Numbers
local floats = negative * numeral ^ -1 * "." * numeral / nodeNum * space
local hexadecimal = "0" * lpeg.S("Xx") * (lpeg.R("af", "AF") + digit) ^ -6 / nodeNum * space
local integers = negative * numeral * -lpeg.S("Xx") / nodeNum * space
local scientific = negative * numeral * lpeg.S("Ee") * numeral / nodeNum * space

local numbers = (hexadecimal + floats + scientific + integers)

-- Parenthesis and Braces
local OP = "(" * space
local CP = ")" * space
local OB = "{" * space
local CB = "}" * space

-- Operators
local comparisonOps =
    lpeg.P("<") * -lpeg.P("=") +
    lpeg.P(">") * -lpeg.P("=") +
    lpeg.P("<=") +
    lpeg.P(">=") +
    lpeg.P("!=") +
    lpeg.P("==")

local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("%*/")) * space
local opExponent = lpeg.C(lpeg.S("^")) * space
local opC = lpeg.C(comparisonOps) * space

-- Variables
local ID = lpeg.C((underscore ^ 0) * alpha * alphanum ^ 0) * space
local var = ID / nodeVar

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
local comparison = lpeg.V("comparison")
local statement = lpeg.V("statement")
local statements = lpeg.V("statements")
local block = lpeg.V("block")

g = space * lpeg.P { statements,
  statements = statement * (SC * statements) ^ -1 / nodeSequence,
  block = OB * statements * SC ^ -1 * CB,
  statement = block + (ID * Assgn * comparison) ^ -1 / nodeAssign,
  value = numbers + OP * comparison * CP + var,
  power = space * lpeg.Ct(value * (opExponent * value) ^ 0) / foldBin,
  product = space * lpeg.Ct(power * (opM * power) ^ 0) / foldBin,
  sum = space * lpeg.Ct(product * (opA * product) ^ 0) / foldBin,
  comparison = lpeg.Ct(sum * (opC * sum) ^ -1) / foldBin
} * -1

local function parse(input)
  return g:match(input)
end

-- Back End
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

local function addCode(state, op)
  local code = state.code
  code[#code + 1] = op
end

local function codeExpression(state, ast)
  if ast.tag == "number" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "binop" then
    codeExpression(state, ast.e1)
    codeExpression(state, ast.e2)
    addCode(state, ops[ast.op])
  elseif ast.tag == "variable" then
    addCode(state, "load")
    addCode(state, ast.var)
  else
    error("invalid tree")
  end
end

local function codeStatement(state, ast)
  if ast.tag == "assignment" then
    codeExpression(state, ast.exp)
    addCode(state, "store")
    addCode(state, ast.id)
  elseif ast.tag == "sequence" then
    codeStatement(state, ast.st1)
    codeStatement(state, ast.st2)
  elseif ast.tag == "empty_statement" then
    -- Do nothing
  else
    error("invalid tree")
  end
end

local function compile(ast)
  local state = { code = {} }
  codeStatement(state, ast)
  return state.code
end

-- Execution

local function run(code, mem, stack)
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
    elseif code[pc] == "load" then
      pc = pc + 1
      local id = code[pc]
      top = top + 1
      stack[top] = mem[id]
    elseif code[pc] == "store" then
      pc = pc + 1
      local id = code[pc]
      mem[id] = stack[top]
      top = top + 1
    else
      error("unknown instruction")
    end

    pc = pc + 1
  end
end

-- Main
function Main(input)
  local stack = {}
  local mem = {}

  if input == nil then
    input = io.read()
  end

  local ast = parse(input)
  -- print(pt.pt(ast))

  local code = compile(ast)
  -- print(pt.pt(code))
  run(code, mem, stack)

  return mem
end

-- print(pt.pt(Main()))

return Main

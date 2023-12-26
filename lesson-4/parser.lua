local lpeg = require "lpeg"
local pt = require "pt"

local maxmatch = 0
local linecount = 1
local function matchPosition(i, position)
  local index = string.sub(i, position, position + 1)

  if string.byte(index) == 59 then
    linecount = linecount + 1
  end

  maxmatch = math.max(maxmatch, position);
  return true
end

local function WS(n)
  return string.rep(" ", n)
end

local function getLine(input, line)
  local substrings = {}

  for substring in input:gmatch("([^" .. "\n" .. "]+)") do
    table.insert(substrings, substring)
  end

  return substrings[line]
end

local function syntaxError(input, max, line)
  local lineError = getLine(input, line)
  local error = string.sub(input, max - math.floor(max / line), max - 3)

  io.stderr:write("** (SyntaxError): ", line, ":", #error, "\n")
  io.stderr:write(WS(4), "|", "\n")
  io.stderr:write(WS(3 - #tostring(line)), line, WS(1), "|", WS(4), lineError, ("\n"))
  io.stderr:write(WS(4), "|", WS(4 + #error), "^", "\n")
end

local function nodeAssign(id, exp)
  if exp then
    return { tag = "assignment", id = id, exp = exp }
  else
    return { tag = "empty_statement" }
  end
end

local function nodeConsole(exp)
  return { tag = "console", exp = exp }
end

local function nodeNum(num)
  return { tag = "number", val = tonumber(num) }
end

local function nodeReturn(exp)
  return { tag = "return", exp = exp }
end

local function nodeSequence(st1, st2)
  if st2 then
    return { tag = "sequence", st1 = st1, st2 = st2 }
  else
    return st1
  end
end

local function nodeVariable(var)
  return { tag = "variable", var = var }
end

-- Tokens
local space = lpeg.S(" \n\t") ^ 0 * lpeg.P(matchPosition)

local alpha = lpeg.R("AZ", "az")
local digit = lpeg.R("09")
local underscore = lpeg.S("_")

local alphanum = alpha + digit + underscore
local numeral = digit ^ 1

local Assgn = "=" * space
local SC = ";" * space
local ret = "return" * space
local console = "@" * space

-- Numbers
local floats = numeral ^ -1 * "." * numeral / nodeNum
local hexadecimal = "0" * lpeg.S("Xx") * (lpeg.R("af", "AF") + digit) ^ -6 / nodeNum
local integers = numeral * -lpeg.S("Xx") / nodeNum
local scientific = numeral * lpeg.S("Ee") * numeral / nodeNum

local numbers = (hexadecimal + floats + scientific + integers) * space

-- Parenthesis and Braces
local OP = "(" * space
local CP = ")" * space
local OB = "{" * space
local CB = "}" * space

-- Operators
local equalityOps = lpeg.P("==") + lpeg.P("!=")
local comparisonOps =
    lpeg.P("<") * -lpeg.P("=") +
    lpeg.P(">") * -lpeg.P("=") +
    lpeg.P("<=") +
    lpeg.P(">=")
local termOps = lpeg.P("+") + lpeg.P("-")
local factorOps = lpeg.P("*") + lpeg.P("/") + lpeg.P("%")

local opComparison = lpeg.C(comparisonOps + equalityOps) * space
local opEquality = lpeg.C(equalityOps) * space
local opTerm = lpeg.C(termOps) * space
local opFactor = lpeg.C(factorOps) * space
local opUnary = lpeg.C(lpeg.P("-"))
local opExp = lpeg.C(lpeg.P("^")) * space

-- Variables
local ID = lpeg.C((underscore ^ 0) * alpha * alphanum ^ 0) * space
local variable = ID / nodeVariable

-- "Grammar"
local function foldBin(lst)
  local tree = lst[1]

  for i = 2, #lst, 2 do
    tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
  end

  return tree
end

local function foldUnary(lst)
  if #lst == 1 then
    return lst[1]
  end

  return { tag = "unaryop", op = lst[1], exp = lst[2] }
end

local statements = lpeg.V("statements")
local block = lpeg.V("block")
local statement = lpeg.V("statement")
local expression = lpeg.V("expression")
local equality = lpeg.V("equality")
local comparison = lpeg.V("comparison")
local term = lpeg.V("term")
local factor = lpeg.V("factor")
local unary = lpeg.V("unary")
local primary = lpeg.V("primary")
local power = lpeg.V("power")

g = space * lpeg.P { statements,
  statements = statement * (SC * statements) ^ -1 / nodeSequence,
  block = OB * statements * (SC ^ -1) * CB,
  statement =
      block +
      (ID * Assgn * expression) / nodeAssign +
      (ret * expression) / nodeReturn +
      (console * expression) / nodeConsole,
  primary = numbers + OP * expression * CP + variable,
  power = lpeg.Ct(primary * (opExp * unary) ^ 0) / foldBin,
  unary = lpeg.Ct(opUnary * unary) / foldUnary + power,
  factor = lpeg.Ct(unary * (opFactor * unary) ^ 0) / foldBin,
  term = lpeg.Ct(factor * (opTerm * factor) ^ 0) / foldBin,
  comparison = lpeg.Ct(term * (opComparison * term) ^ 0) / foldBin,
  equality = lpeg.Ct(comparison * (opEquality * comparison) ^ 0) / foldBin,
  expression = equality
} * -1

local Parser = {}

function Parser.parse(input)
  local result = g:match(input)

  if (not result) then
    syntaxError(input, maxmatch, linecount)
    os.exit(1)
  end

  return result
end

return Parser

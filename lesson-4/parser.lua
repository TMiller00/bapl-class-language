local lpeg = require "lpeg"
local pt = require "pt"

local function I(msg)
  return lpeg.P(function()
    print(msg); return true
  end)
end

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
  local errorPosition = math.floor(max / line)

  io.stderr:write("** (SyntaxError): ", line, ":", errorPosition, "\n")
  io.stderr:write(WS(4), "|", "\n")
  io.stderr:write(WS(3 - #tostring(line)), line, WS(1), "|", WS(4), lineError, ("\n"))
  io.stderr:write(WS(4), "|", WS(4), WS(errorPosition - 1), "^", "\n")
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
local space = lpeg.V("space")

local alpha = lpeg.R("AZ", "az")
local digit = lpeg.R("09")
local underscore = lpeg.S("_")
local decimal = lpeg.P(".")

local alphanum = alpha + digit + underscore
local numeral = digit ^ 1

-- Utilties For Tokens and Reserved Words

-- My preference is not to use this function,
-- but keeping it here for reference

local function Token(t)
  return t * space
end

local reservedWords = { "return", "if" }
local excludedWords = lpeg.P(false)

for i = 1, #reservedWords do
  excludedWords = excludedWords + reservedWords[i]
end

excludedWords = excludedWords * -alphanum

local function ReservedWord(rw)
  assert(excludedWords:match(rw))
  return rw * -alphanum * space
end

local function ReservedWordsWithMatches(input, position)
  for i = 1, #reservedWords do
    local currentWord = string.sub(input, position - #reservedWords[i] - 1, position - 2)

    if (reservedWords[i] == currentWord) then
      return false
    end
  end

  return true
end

-- Assignment

local Assgn = Token("=")
local SC = Token(";")
local ret = ReservedWord("return")
local console = Token("@")

local comment = lpeg.P("#") * (lpeg.P(1) - "\n") ^ 0
local multilineComment = "#{" * (lpeg.P(1) - "#}") ^ 0 - "#}"

-- Numbers
local floats = numeral ^ -1 * decimal * numeral ^ -1 / nodeNum
local hexadecimal = "0" * lpeg.S("Xx") * lpeg.R("09", "af", "AF") ^ 1 / nodeNum
local integers = numeral ^ 1 / nodeNum
local scientific = numeral * lpeg.S("Ee") * numeral / nodeNum

local numbers = (hexadecimal + floats + scientific + integers) * space

-- Parenthesis and Braces
local OP = Token("(")
local CP = Token(")")
local OB = Token("{")
local CB = Token("}")

-- Operators
local equalityOps = lpeg.P("==") + lpeg.P("!=")
local comparisonOps = lpeg.P("<=") + lpeg.P(">=") + lpeg.P("<") + lpeg.P(">")
local termOps = lpeg.P("+") + lpeg.P("-")
local factorOps = lpeg.P("*") + lpeg.P("/") + lpeg.P("%")

local opComparison = lpeg.C(comparisonOps) * space
local opEquality = lpeg.C(equalityOps) * space
local opTerm = lpeg.C(termOps) * space
local opFactor = lpeg.C(factorOps) * space
local opUnary = lpeg.C(lpeg.P("-"))
local opExp = lpeg.C(lpeg.P("^")) * space

-- Variables
-- local ID = (lpeg.C((underscore ^ 0) * alpha * alphanum ^ 0) - excludedWords) * space
local ID = lpeg.C((underscore ^ 0) * alpha * alphanum ^ 0) * space * lpeg.P(ReservedWordsWithMatches)

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
local primary = lpeg.V("primary")
local power = lpeg.V("power")
local unary = lpeg.V("unary")
local factor = lpeg.V("factor")
local term = lpeg.V("term")
local comparison = lpeg.V("comparison")
local equality = lpeg.V("equality")
local expression = lpeg.V("expression")

g = lpeg.P { "program",
  program = space * statements * -1,
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
  expression = equality,
  space = (lpeg.S(" \t\n") + multilineComment + comment) ^ 0 * lpeg.P(matchPosition)
}

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

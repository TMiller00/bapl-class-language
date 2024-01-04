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

local function node(tag, ...)
  local labels = table.pack(...)
  local params = table.concat(labels, ", ")
  local fields = string.gsub(params, "(%w+)", "%1 = %1")
  local code = string.format(
    "return function (%s) return {tag = '%s', %s} end",
    params, tag, fields
  )
  return assert(load(code))()
end

local function altNode(tag, ...)
  local labels = table.pack(...)

  return function(...)
    local n = {}
    local params = table.pack(...)

    n["tag"] = tag

    for kl, vl in ipairs(labels) do
      for kp, vp in ipairs(params) do
        if (kl == kp) then
          n[vl] = vp
        end
      end
    end

    return n
  end
end

local nodeConsole = node("console", "exp")
local nodeReturn = node("return", "exp")
local nodeVariable = node("variable", "var")
local nodeNum = node("number", "val")
local nodeIf = node("if1", "cond", "th")

local function nodeAssign(id, exp)
  if exp then
    return { tag = "assignment", id = id, exp = exp }
  else
    return { tag = "empty_statement" }
  end
end

local function nodeSequence(st1, st2)
  if st2 then
    return { tag = "sequence", st1 = st1, st2 = st2 }
  else
    return st1
  end
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

-- My preference is not to use this function,
-- but keeping it here for reference

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
local if1 = ReservedWord("if")

local comment = lpeg.P("#") * (lpeg.P(1) - "\n") ^ 0
local multilineComment = "#{" * (lpeg.P(1) - "#}") ^ 0 - "#}"

-- Numbers
local float = (numeral * decimal * numeral ^ -1) + (decimal * numeral)
local hexadecimal = "0" * lpeg.S("Xx") * lpeg.R("09", "af", "AF") ^ 1
local integer = numeral ^ 1
local scientific = (float + numeral) * lpeg.S("Ee") * lpeg.P("-") ^ -1 * numeral

local numbers = (hexadecimal + scientific + float + integer) / tonumber / nodeNum * space

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
local unaryOps = lpeg.P("!") + lpeg.P("-")

local opComparison = lpeg.C(comparisonOps) * space
local opEquality = lpeg.C(equalityOps) * space
local opTerm = lpeg.C(termOps) * space
local opFactor = lpeg.C(factorOps) * space
local opUnary = lpeg.C(unaryOps)
local opExp = lpeg.C(lpeg.P("^")) * space

-- Variables
local ID = (lpeg.C((underscore ^ 0) * alpha * alphanum ^ 0) - excludedWords) * space
-- local ID = lpeg.C((underscore ^ 0) * alpha * alphanum ^ 0) * space * lpeg.P(ReservedWordsWithMatches)

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
      (if1 * expression * block) / nodeIf +
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

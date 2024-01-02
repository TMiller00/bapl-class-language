local binaryOps = {
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
  ["!="] = "neq",
}

local unaryOps = {
  ["-"] = "neg",
}

local function addCode(state, op)
  local code = state.code
  code[#code + 1] = op
end

local function encodeVariable(op, state, id)
  local num = state.vars[id]

  if not num then
    if op == "load" then
      error("Undefined variable")
    elseif op == "store" then
      num = state.nvars + 1
      state.nvars = num
      state.vars[id] = num
    else
      error("Undefined op code")
    end
  end

  return num
end

local function codeExpression(state, ast)
  if ast.tag == "number" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "binop" then
    codeExpression(state, ast.e1)
    codeExpression(state, ast.e2)
    addCode(state, binaryOps[ast.op])
  elseif ast.tag == "unaryop" then
    codeExpression(state, ast.exp)
    addCode(state, unaryOps[ast.op])
  elseif ast.tag == "variable" then
    addCode(state, "load")
    addCode(state, encodeVariable("load", state, ast.var))
  else
    error("invalid tree")
  end
end

local function codeStatement(state, ast)
  if ast.tag == "assignment" then
    codeExpression(state, ast.exp)
    addCode(state, "store")
    addCode(state, encodeVariable("store", state, ast.id))
  elseif ast.tag == "sequence" then
    codeStatement(state, ast.st1)
    codeStatement(state, ast.st2)
  elseif ast.tag == "return" then
    codeExpression(state, ast.exp)
    addCode(state, "return")
  elseif ast.tag == "console" then
    codeExpression(state, ast.exp)
    addCode(state, "console")
  elseif ast.tag == "empty_statement" then
    -- Do nothing
  else
    error("invalid tree")
  end
end

local Compiler = {}

function Compiler.compile(ast)
  local state = { code = {}, vars = {}, nvars = 0 }
  codeStatement(state, ast)

  addCode(state, "push")
  addCode(state, 0)
  addCode(state, "return")

  return state.code
end

return Compiler

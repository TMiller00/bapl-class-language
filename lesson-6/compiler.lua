local pt = require "pt"

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
  ["and"] = "and",
  ["or"] = "or",
}

local unaryOps = {
  ["-"] = "neg",
  ["!"] = "not"
}

local Compiler = { code = {}, vars = {}, nvars = 0 }

function Compiler:addCode(op)
  local code = self.code
  code[#code + 1] = op
end

function Compiler:correctJump(jump)
  self.code[jump] = self:currentPosition()
end

function Compiler:correctJumpRelative(jump)
  self.code[jump] = self:currentPosition() - jump
end

function Compiler:currentPosition()
  return #self.code
end

function Compiler:codeJump(op)
  self:addCode(op)
  self:addCode(0)
  return self:currentPosition()
end

function Compiler:codeJumpBackWard(op, label)
  self:addCode(op)
  self:addCode(label)
end

function Compiler:encodeVariable(id, op)
  local num = self.vars[id]

  if not num then
    if op == "load" then
      error("Undefined variable")
    elseif op == "store" then
      num = self.nvars + 1
      self.nvars = num
      self.vars[id] = num
    else
      error("Undefined op code")
    end
  end

  return num
end

function Compiler:codeExpression(ast)
  if ast.tag == "number" then
    self:addCode("push")
    self:addCode(ast.val)
  elseif ast.tag == "binop" then
    if ast.op == "and" then
      self:codeExpression(ast.e1)
      local jump = self:codeJump("jumpZeroPop")
      self:codeExpression(ast.e2)
      self:correctJump(jump)
    elseif ast.op == "or" then
      self:codeExpression(ast.e1)
      local jump = self:codeJump("jumpNonZeroPop")
      self:codeExpression(ast.e2)
      self:correctJump(jump)
    else
      self:codeExpression(ast.e1)
      self:codeExpression(ast.e2)
      self:addCode(binaryOps[ast.op])
    end
  elseif ast.tag == "unaryop" then
    self:codeExpression(ast.exp)
    self:addCode(unaryOps[ast.op])
  elseif ast.tag == "variable" then
    self:addCode("load")
    self:addCode(self:encodeVariable(ast.var, "load"))
  elseif ast.tag == "indexed" then
    self:codeExpression(ast.array)
    self:codeExpression(ast.index)
    self:addCode("getArray")
  elseif ast.tag == "new" then
    self:codeExpression(ast.size)
    self:addCode("newArray")
  else
    error("invalid tree")
  end
end

function Compiler:codeAssignment(ast)
  local lhs = ast.lhs
  if lhs.tag == "variable" then
    self:codeExpression(ast.exp)
    self:addCode("store")
    self:addCode(self:encodeVariable(lhs.var, "store"))
  elseif lhs.tag == "indexed" then
    self:codeExpression(lhs.array)
    self:codeExpression(lhs.index)
    self:codeExpression(ast.exp)
    self:addCode("setArray")
  else
    error("Unknown tag")
  end
end

function Compiler:codeStatement(ast)
  if ast.tag == "assignment" then
    self:codeAssignment(ast)
  elseif ast.tag == "sequence" then
    self:codeStatement(ast.st1)
    self:codeStatement(ast.st2)
  elseif ast.tag == "return" then
    self:codeExpression(ast.exp)
    self:addCode("return")
  elseif ast.tag == "console" then
    self:codeExpression(ast.exp)
    self:addCode("console")
  elseif ast.tag == "_while" then
    local initialLabel = self:currentPosition()
    self:codeExpression(ast.cond)
    local jump = self:codeJump("jumpZero")
    self:codeStatement(ast.body)
    self:codeJumpBackWard("jumpRegular", initialLabel)
    self:correctJump(jump)
  elseif ast.tag == "if1" then
    -- Jump Zero
    self:codeExpression(ast.cond)
    local jump = self:codeJump("jumpZero")
    self:codeStatement(ast.th)

    if ast.el == nil then
      self:correctJump(jump)
    else
      local jump2 = self:codeJump("jumpRegular")
      self:correctJump(jump)
      self:codeStatement(ast.el)
      self:correctJump(jump2)
    end

    -- JumpRelative
    -- self:codeExpression(ast.cond)
    -- local jump = self:codeJump("jumpRelative")
    -- self:codeStatement(ast.th)
    -- self:correctJumpRelative(jump)
  elseif ast.tag == "empty_statement" then
    -- Do nothing
  else
    error("invalid tree")
  end
end

function Compiler.compile(ast)
  Compiler:codeStatement(ast)

  Compiler:addCode("push")
  Compiler:addCode(0)
  Compiler:addCode("return")

  return Compiler.code
end

return Compiler

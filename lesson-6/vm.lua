local VM = {}
local pt = require "pt"

function VM.run(code, mem, stack)
  local pc = 1
  local top = 0

  while true do
    --[[
    io.write("--> ")
    for i = 1, top do io.write(stack[i], " ") end
    io.write("\n", code[pc], "\n")
    --]]

    if code[pc] == "return" then
      return
    elseif code[pc] == "console" then
      io.write(stack[top], "\n")
      top = top - 1
    elseif code[pc] == "push" then
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
    elseif code[pc] == "neg" then
      stack[top] = -stack[top]
    elseif code[pc] == "not" then
      stack[top] = not stack[top]
    elseif code[pc] == "load" then
      pc = pc + 1
      local id = code[pc]
      top = top + 1
      stack[top] = mem[id]
    elseif code[pc] == "store" then
      pc = pc + 1
      local id = code[pc]
      mem[id] = stack[top]
      top = top - 1
    elseif code[pc] == "jumpRegular" then
      pc = code[pc + 1]
    elseif code[pc] == "jumpRelative" then
      pc = pc + 1
      if stack[top] == 0 or stack[top] == nil then
        pc = pc + code[pc]
      end
      top = top - 1
    elseif code[pc] == "jumpZero" then
      pc = pc + 1
      if stack[top] == 0 or stack[top] == nil then
        pc = code[pc]
      end
      top = top - 1
    elseif code[pc] == "jumpZeroPop" then
      pc = pc + 1
      if stack[top] == 0 or stack[top] == nil then
        pc = code[pc]
      else
        top = top - 1
      end
    elseif code[pc] == "jumpNonZeroPop" then
      pc = pc + 1
      if stack[top] == 0 or stack[top] == nil then
        top = top - 1
      else
        pc = code[pc]
      end
    else
      error("unknown instruction")
    end

    pc = pc + 1
  end
end

return VM

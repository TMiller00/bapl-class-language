local parser = require "parser"
local compiler = require "compiler"
local vm = require "vm"
local pt = require "pt"

-- Korba
-- Tek
-- Lys
-- Axo
-- Tern
-- Rook

function Main(input)
  local stack = {}
  local mem = {}

  if input == nil then
    input = io.read()
  end

  local ast = parser.parse(input)
  local code = compiler.compile(ast)
  vm.run(code, mem, stack)

  return stack[1]
end

print(pt.pt(Main()))
-- Main()

return Main

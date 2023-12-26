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

  if not input then
    input = io.read("*all")
  end


  local ast = parser.parse(input)
  local code = compiler.compile(ast)
  vm.run(code, mem, stack)

  return stack[1]
end

print(pt.pt(Main()))
-- Main()

return Main

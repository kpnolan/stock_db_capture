require 'rubygems'
require 'ruby-debug'

TypeDecl = Struct.new(:name, :key, :output, :arity, :convert_block) do
  @@check = true
  def initialize(name, key, output, &block)
    self.name = name
    self.key = key
    self.output = output
    self.convert_block = block
    self.arity = block.arity
  end
end
def TypeDecl.no_runtime_check(true_false)
  @@check = ! true_false
end

TypeDecl.no_runtime_check(false)


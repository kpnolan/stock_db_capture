#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
class Task
  attr_reader :params, :block, :meth

  def initialize(params={})
    @params = params
  end

  def get_binding()
    binding
  end

  def b(a,b,c)
    puts 'in b'
    puts a,b,c
    puts params.inspect
  end

  def a()
    self.instance_exec(10,20,20,&:b)
  end
  def wrap1()
    @block = lambda do |a,b,c,d|
      puts a,b,c,d
      puts params.inspect
    end
  end
  def wrap2(params)
    @block = lambda do
      puts params.inspect
    end
  end

  def set_meth(&m)
    @meth = m
  end

end

baz = lambda { puts params }

def bar(a,b)
  puts a,b
#  puts args
  puts params
end

def foo(obj)
  binding = obj.get_binding
  binding.eval('puts "foo: #{params}"')
end

b = :bar.to_proc

ary = [:fe, :fy, :fo, :fum]

p1 = Task.new(:a => 1, :b => 2, :c => 3)
#p1.wrap1()
#p1.instance_exec(p1, 1,2, &b)
p1.instance_exec(p1, 10,20, &b)

#foo(p1)


#p2 = Task.new(:d => 4, :e => 5, :f => 6)
#p2.wrap2()

#p1.block.call()


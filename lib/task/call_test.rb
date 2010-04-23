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


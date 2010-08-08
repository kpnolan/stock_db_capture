class A
  def initialize(a,b,c)
    @a, @b, @c = a,b,c
  end

  def foo()
    @a+@b
  end
end

class B < A
  def initialize(a,b,c,d)
    super(a,b,c)
    @d = d
  end
  def foo()
    super()+@d
  end
end

a = A.new(1,2,3)
b = B.new(1,2,3,4)

p a.foo
p b.foo


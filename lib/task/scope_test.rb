module Sample
  @@var = { }
  def store(k,v)
    @@var[k] = v
  end
  def read(key)
    @@var[key]
  end

  def dump(prefix)
    puts prefix + @@var.inspect
  end
end

class Class1
  include Sample
end

i1 = Class1.new
i1.store(:a, 1)
i1.store(:b, 2)
i1.dump('i1: ')

class Class2
  include Sample
end
p i1.dump('after Class2 i1: ')

i2 = Class2.new
i2.store(:c, 3)
i2.store(:d, 4)

p i1.dump('i1: ')
p i2.dump('i2: ')


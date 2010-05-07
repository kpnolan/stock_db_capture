
def create_closure(a,b,c)
  lambda { puts [a,b,c].inspect }
end


closure = create_closure(1,2,3)

closure.call()

class CbTest
  def completer_id(id, results)
    puts "ID: #{id} results: #{results.inspect}"
  end

  def completer_noid(results)
    puts "Just results: #{results.inspect}"
  end
end

test_obj = CbTest.new

def callback(object = nil, method = nil, id = nil, &blk)
  if object && method && id
    lambda { |*args| object.send method, id, *args }
  elsif object && method
    lambda { |*args| object.send method, *args }
  else
    if object.respond_to? :call
      object
    else
      blk || raise(ArgumentError)
    end
  end
end


cb1 = callback(test_obj, :completer_id, 666)
cb1.call([1,2,3,4,5,6,7,8,9,0])

cb2 = callback(test_obj, :completer_noid)
cb2.call([1,2,3,4,5,6,7,8,9,0])



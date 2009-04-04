class Foo
  def method_missing(method, *args)
    puts "#{method}(#{args.join(', ')})"
  end

  def bar
    baz
  end
end

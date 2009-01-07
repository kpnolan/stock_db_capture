module CurrentMethod
  def this_method
    caller[0][/`([^']*)'/, 1]
  end
  def calling_method
    caller[1][/`([^']*)'/, 1]
  end
end

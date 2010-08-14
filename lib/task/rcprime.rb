class Integer
  def to_proxy; self; end
  def dereference; self; end
  def is_proxy?; true; end
end

class TrueClass
  def to_proxy; self; end
  def dereference; self; end
  def is_proxy?; true; end
end

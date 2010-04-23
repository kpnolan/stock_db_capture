class Class
  def cattr_accessor_with_default(name, value = nil)
    cattr_accessor name
    self.send("#{name}=", value) if value
  end

  def cattr_reader_with_default(name, value = nil)
    cattr_reader name
    self.send("#{name}=", value) if value
  end
end # Class

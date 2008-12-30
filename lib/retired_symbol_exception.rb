class RetiredSymbolException < Exception

  attr_accessor :symbol

  def initialize(sym)
    self.symbol = sym
  end
end

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class RetiredSymbolException < Exception

  attr_accessor :symbol

  def initialize(sym)
    self.symbol = sym
  end
end

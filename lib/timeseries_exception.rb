# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class TimeseriesException < Exception
  def initialize(message)
    super
  end
end

class DelistedStockException < TimeseriesException
  def initialize(symbol)
    super(symbol+' has been delisted')
  end
end

include 'singleton'

module TradingSimulator
  class OrderProcessor
    include Singleton
    
    def place_order(order)
    end
    
    def execute_order(order)
    end
  end
end

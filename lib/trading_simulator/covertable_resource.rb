module TradingSimulator
  class ConvertableResrouce < Struct.new(:count, :units)
    def initialize(count, units)
      super(count, units)
    end
  end

  class Position < ConvertableResource
  end

  class Currency < ConvertableResource
  end

  class Equity < ConvertableResource
  end
end

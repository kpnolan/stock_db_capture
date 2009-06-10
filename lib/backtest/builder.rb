require 'backtester'

module Backtest

  class BacktestrException
    def initialize(name)
      super("Problem with statement named: #{name}")
    end
  end

  class Builder

    attr_reader :options, :description, :backtests

    def initialize(options)
      @options = options
      @backtests = []
    end

    def apply(strategy, populations)
      populations = [ populations ] unless populations.is_a? Array
      @backtests << Backtester.new(strategy, populations, description, options)
    end

    def desc(string)
      @description = string
    end

    def run(logger)
      backtests.each do |backtest|
        backtest.run(logger)
      end
    end
  end
end

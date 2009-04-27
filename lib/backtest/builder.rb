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

    def apply(strategy, populations, &block)
      raise ArgumentError.new("Block missing") unless block_given?
      populations = [ populations ] unless populations.is_a? Array
      @backtests << Backtester.new(strategy, populations, description, options, &block)
    end

    def desc(string)
      @description = string
    end

    def run()
      backtests.each do |backtest|
        backtest.run
      end
    end
  end
end

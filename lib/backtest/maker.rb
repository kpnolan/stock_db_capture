require 'backtester'

module Backtest
  module Maker
    def self.backtests(options, &block)
      $backtester = builder = Backtest::Builder.new(options)
      builder.instance_eval(&block)
    end
  end
end

def backtests(options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Backtest::Maker.backtests(options, &block)
end

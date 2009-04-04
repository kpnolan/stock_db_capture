module Backtest
  module Maker
    def define_backtests(options={}, &block)
      $backtester = builder = Backtests::Builder.new()
      builder.instance_eval(&block)
    end
  end
end

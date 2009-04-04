require 'strategy_engine'

class RsiStrategy < StrategyEngine
  def compute_open_indexes()
    memo = ts.rsi :result => :memo
    buy_indexes = memo.threshold_crossing(30, :real, :gt)
  end
end

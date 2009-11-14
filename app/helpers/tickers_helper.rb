module TickersHelper
  def tickers_path
    objects_path
  end

  def ticker_path(obj)
    object_path(obj)
  end

  def format_flags(ticker)
    cols = [:etf, :active, :delisted]
    flags = cols.inject('') { |str, col| str << "#{col}, " if ticker[col]; str }
    flags.ends_with?(', ') ? flags.slice!(0..-3) : ''
  end
end

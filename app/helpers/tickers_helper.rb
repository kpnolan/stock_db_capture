module TickersHelper
  def tickers_path
    objects_path
  end

  def ticker_path(obj)
    object_path(obj)
  end
end

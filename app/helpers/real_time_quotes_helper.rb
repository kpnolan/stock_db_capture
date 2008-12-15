module RealTimeQuotesHelper
  def real_time_quotes_path
    objects_path
  end

  def real_time_quote_path(obj)
    object_path(obj)
  end
end

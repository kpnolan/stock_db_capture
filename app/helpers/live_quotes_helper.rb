module LiveQuotesHelper
  def live_quotes_path
    objects_path
  end

  def live_quote_path(obj)
    object_path(obj)
  end
end

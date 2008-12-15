module ExchangesHelper
  def exchanges_path
    objects_path
  end

  def exchange_path(obj)
    object_path(obj)
  end
end

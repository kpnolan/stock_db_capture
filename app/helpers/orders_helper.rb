module OrdersHelper
  def orders_path
    objects_path
  end

  def order_path(obj)
    object_path(obj)
  end
end

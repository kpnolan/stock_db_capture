module DailyClosesHelper
  def daily_closes_path
    objects_path
  end

  def daily_close_path(obj)
    object_path(obj)
  end
end

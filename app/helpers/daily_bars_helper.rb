module DailyBarsHelper
  def daily_bars_path
    objects_path
  end

  def daily_bar_path(obj)
    object_path(obj)
  end
end

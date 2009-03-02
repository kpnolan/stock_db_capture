module PositionsHelper
  def positions_path
    objects_path
  end

  def position_path(obj)
    object_path(obj)
  end
end

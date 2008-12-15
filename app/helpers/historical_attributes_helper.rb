module HistoricalAttributesHelper
  def historical_attributes_path
    objects_path
  end

  def historical_attribute_path(obj)
    object_path(obj)
  end
end

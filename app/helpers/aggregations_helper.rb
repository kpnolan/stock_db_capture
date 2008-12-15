module AggregationsHelper
  def aggregations_path
    objects_path
  end

  def aggregation_path(obj)
    object_path(obj)
  end
end

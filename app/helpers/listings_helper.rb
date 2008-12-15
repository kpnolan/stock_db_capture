module ListingsHelper
  def listings_path
    objects_path
  end

  def listing_path(obj)
    object_path(obj)
  end
end

module CurrentListingHelper
  def current_listings_path
    objects_path
  end

  def current_listing_path(obj)
    object_path(obj)
  end
end

module ListingCategoriesHelper
  def listing_categories_path
    objects_path
  end

  def listing_category_path(obj)
    object_path(obj)
  end
end

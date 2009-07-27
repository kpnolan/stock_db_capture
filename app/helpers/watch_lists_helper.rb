module WatchListsHelper
  def watch_lists_path
    objects_path
  end

  def watch_list_path(obj)
    object_path(obj)
  end
end

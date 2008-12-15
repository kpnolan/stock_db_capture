module <%= controller_class_name %>Helper
  def <%= plural_name -%>_path
    objects_path
  end

  def <%= singular_name -%>_path(obj)
    object_path(obj)
  end
end

module SnapshotsHelper
  def snapshots_path
    objects_path
  end

  def snapshot_path(obj)
    object_path(obj)
  end
end

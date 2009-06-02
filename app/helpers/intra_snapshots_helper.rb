module IntraSnapshotsHelper
  def intra_snapshots_path
    objects_path
  end

  def intra_snapshot_path(obj)
    object_path(obj)
  end
end

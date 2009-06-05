class RenameStartTimeInSnapshots < ActiveRecord::Migration
  def self.up
    rename_column :intra_snapshots, :start_time, :snap_time
  end

  def self.down
    rename_column :intra_snapshots, :snap_time, :start_time
  end
end

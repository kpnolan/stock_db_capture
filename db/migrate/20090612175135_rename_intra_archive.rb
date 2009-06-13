class RenameIntraArchive < ActiveRecord::Migration
  def self.up
    rename_table :intra_day_archive, :intra_day_archives
  end

  def self.down
    rename_table :intra_day_archives, :intra_day_archive
  end
end

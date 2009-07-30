class RenameUpdateAt < ActiveRecord::Migration
  def self.up
    rename_column :watch_list, :updated_at, :last_snaptime
  end

  def self.down
    rename_column :watch_list, :last_snaptime, :updated_at
  end
end

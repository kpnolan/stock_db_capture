class AddJoinToScan < ActiveRecord::Migration
  def self.up
    add_column :scans, :join, :string
  end

  def self.down
    remove_column :scans, :join
  end
end

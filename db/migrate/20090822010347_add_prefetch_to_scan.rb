class AddPrefetchToScan < ActiveRecord::Migration
  def self.up
    add_column :scans, :prefetch, :integer
  end

  def self.down
    remove_column :scans, :prefetch
  end
end

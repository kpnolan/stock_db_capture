class AddTableNameToScan < ActiveRecord::Migration
  def self.up
    add_column :scans, :table_name, :string
  end

  def self.down
    remove_column :scans, :table_name
  end
end

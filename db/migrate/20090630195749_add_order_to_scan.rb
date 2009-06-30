class AddOrderToScan < ActiveRecord::Migration
  def self.up
    add_column :scans, :order_by, :string
  end

  def self.down
    remove_column :scans, :order_by
  end
end

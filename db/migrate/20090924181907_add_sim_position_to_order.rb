class AddSimPositionToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :sim_position_id, :integer
  end

  def self.down
    remove_column :orders, :sim_position_id
  end
end

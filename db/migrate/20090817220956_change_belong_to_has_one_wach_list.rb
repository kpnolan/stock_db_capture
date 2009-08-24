class ChangeBelongToHasOneWachList < ActiveRecord::Migration
  def self.up
    remove_column :watch_list, :tda_position_id
    add_column :tda_positions, :watch_list_id, :integer, :references => :watch_list
  end

  def self.down
    add_column :watch_list, :tda_position_id, :integer
    remove_column :tda_positions, :watch_list_id
  end
end

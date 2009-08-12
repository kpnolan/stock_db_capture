class AddIndicatorIdToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :indicator_id, :integer, :references => nil
  end

  def self.down
    remove_column :positions, :indicator_id
  end
end

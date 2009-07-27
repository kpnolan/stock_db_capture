class AddCloseFlagToTdaPosition < ActiveRecord::Migration
  def self.up
    add_column :tda_positions, :com, :boolean
  end

  def self.down
    remove_column :tda_positions, :com
  end
end

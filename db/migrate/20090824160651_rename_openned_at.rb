class RenameOpennedAt < ActiveRecord::Migration
  def self.up
    rename_column :tda_positions, :openned_at, :opened_at
  end

  def self.down
    rename_column :tda_positions, :opened_at, :openned_at
  end
end

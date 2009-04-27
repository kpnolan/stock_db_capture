class ReworkPosition < ActiveRecord::Migration
  def self.up
    remove_column :positions, :ticker_population_id
    add_column :positions, :scan_id, :integer
  end

  def self.down
    add_column :positions, :open, :boolean
    add_column :positions, :population_id, :integer, :references => nil
    add_column :positions, :ticker_population_id, :references => nil
    remove_column :positions, :scan_id, :integer
  end
end

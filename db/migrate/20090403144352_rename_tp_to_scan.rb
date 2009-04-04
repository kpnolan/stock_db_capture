class RenameTpToScan < ActiveRecord::Migration
  def self.up
    rename_table :ticker_populations, :scans
  end

  def self.down
    rename_table :scans, :ticker_populations
  end
end

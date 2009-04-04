class AddDescriptionToTickerPopulation < ActiveRecord::Migration
  def self.up
    add_column :ticker_populations, :description, :string
  end

  def self.down
    remove_column :ticker_populations, :description
  end
end

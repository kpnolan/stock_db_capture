class ChangePortfolioToPopulation < ActiveRecord::Migration
  def self.up
    remove_column :positions, :portfolio_id
    add_column :positions, :ticker_population_id, :integer
  end

  def self.down
    add_column :positions, :portfolio_id, :integer
    remove_column :positions, :ticker_population_id
  end
end

class ChangeNameOnPopulation < ActiveRecord::Migration
  def self.up
    rename_column :ticker_populations, :start , :start_date
    rename_column :ticker_populations, :end, :end_date
    rename_column :ticker_populations, :sql_query, :conditions
  end

  def self.down
    rename_column :ticker_populations, :start_date, :start
    rename_column :ticker_populations, :end_date, :end
    rename_column :ticker_populations, :conditions, :sql_query
  end
end

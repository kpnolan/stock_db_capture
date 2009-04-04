class CreateTickerPopulations < ActiveRecord::Migration
  def self.up
    create_table :ticker_populations, :force => true do |t|
      t.string :name
      t.date :start
      t.date :end
      t.text :sql_query
    end
  end

  def self.down
    drop_table :ticker_populations
  end
end

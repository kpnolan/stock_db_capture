class CreateAggregates < ActiveRecord::Migration
  def self.up
    create_table :aggregates do |t|
      t.integer :ticker_id
      t.date :date
      t.datetime :start
      t.float :open
      t.float :close
      t.float :high
      t.float :low
      t.integer :volume
      t.integer :period
   end
  end

  def self.down
    drop_table :aggregates
  end
end

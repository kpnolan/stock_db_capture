class CreateAggregations < ActiveRecord::Migration
  def self.up
    create_table :aggregations, :force => true do |t|
      t.integer :ticker_id
      t.date :date
      t.float :open
      t.float :close
      t.float :high
      t.float :low
      t.float :adj_close
      t.integer :volume
      t.integer :week
      t.integer :month
      t.integer :sample_count
      t.datetime :created_at
      t.datetime :updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :aggregations
  end
end

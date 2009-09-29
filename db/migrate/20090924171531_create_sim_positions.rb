class CreateSimPositions < ActiveRecord::Migration
  def self.up
    create_table :sim_positions, :force => true do |t|
      t.datetime :entry_date
      t.datetime :exit_date
      t.integer :quantity
      t.float :entry_price
      t.float :exit_price
      t.float :nreturn
      t.float :roi
      t.integer :days_held
      t.integer :eorder_id, :references => :orders
      t.integer :xorder_id, :references => :orders
      t.integer :ticker_id
      t.integer :position_id
    end
  end

  def self.down
    drop_table :sim_positions
  end
end

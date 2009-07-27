class CreateTdaPositions < ActiveRecord::Migration
  def self.up
    create_table :tda_positions, :force => true do |t|
      t.integer :ticker_id
      t.integer :estrategy_id, :references => :strategies
      t.integer :xstrategy_id, :references => :strategies
      t.float :entry_price
      t.float :exit_price
      t.float :curr_price
      t.date :entry_date
      t.date :exit_date
      t.integer :rum_shares
      t.integer :days_held
      t.boolean :stop_loss
      t.float :nreturn
      t.float :rretrun
      t.integer :eorderid
      t.integer :xorderid
      t.datetime :openned_at
      t.datetime :closed_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :tda_positions
  end
end

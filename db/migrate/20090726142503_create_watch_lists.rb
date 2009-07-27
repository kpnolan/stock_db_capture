class CreateWatchLists < ActiveRecord::Migration
  def self.up
    create_table :watch_list, :force => true do |t|
      t.integer :ticker_id
      t.integer :tda_position_id
      t.float :target_price
      t.float :target_ival
      t.float :curr_price
      t.float :curr_ival
      t.float :predicted_price
      t.float :predicted_ival
      t.datetime :crossed_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :watch_list
  end
end

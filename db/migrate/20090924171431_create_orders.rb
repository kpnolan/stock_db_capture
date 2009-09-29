class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders, :force => true do |t|
      t.string   :txn, :limit => 3, :null => false
      t.string   :type, :limit => 3, :null => false
      t.string   :expiration, :limit => 3, :null => false
      t.integer  :quantity
      t.datetime :placed_at
      t.datetime :filled_at
      t.float    :activation_price
      t.float    :order_price
      t.float    :fill_price
      t.integer  :ticker_id, :null => false
      t.integer  :position_id
    end
  end

  def self.down
    drop_table :orders
  end
end

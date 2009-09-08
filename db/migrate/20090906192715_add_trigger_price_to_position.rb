class AddTriggerPriceToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :trigger_price, :float
  end

  def self.down
    remove_column :positions, :trigger_price
  end
end

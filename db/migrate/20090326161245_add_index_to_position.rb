class AddIndexToPosition < ActiveRecord::Migration
  def self.up
    add_index :positions, [:portfolio_id, :ticker_id]
  end

  def self.down
    remove_index :positions, [:portfolio_id, :ticker_id]
  end
end

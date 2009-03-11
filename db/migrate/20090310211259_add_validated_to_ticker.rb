class AddValidatedToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :validated, :boolean
  end

  def self.down
    remove_column :tickers, :validated
  end
end

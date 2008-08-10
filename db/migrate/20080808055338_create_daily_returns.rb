require 'rubygems'
require 'ruby-debug'

class CreateDailyReturns < ActiveRecord::Migration
  def self.up
    create_table :daily_returns do |t|
      TradingDBLoader.create_table_from_fields(t, :daily_returns, 's')
      t.timestamps
    end
  end

  def self.down
    drop_table :daily_returns
  end
end

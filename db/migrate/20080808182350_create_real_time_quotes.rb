class CreateRealTimeQuotes < ActiveRecord::Migration
  def self.up
    create_table :real_time_quotes do |t|
      TradingDBLoader.create_table_from_fields(t, :real_time_quotes, 'r')

      t.timestamps
    end
  end

  def self.down
    drop_table :real_time_quotes
  end
end

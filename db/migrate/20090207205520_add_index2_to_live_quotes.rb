class AddIndex2ToLiveQuotes < ActiveRecord::Migration
  def self.up
    add_index :live_quotes, [ :ticker_id, :date ]
  end

  def self.down
    add_index :live_quotes, :colums => [ :ticker_id, :date ]
  end
end

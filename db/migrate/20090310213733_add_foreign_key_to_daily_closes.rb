class AddForeignKeyToDailyCloses < ActiveRecord::Migration
  def self.up
    add_foreign_key(:daily_closes, :ticker_id, :tickers, :id, :on_delete => :restrict, :on_update => :cascade, :name => :daily_closes_fk_ticker_id_tickers_id)
  end

  def self.down
    remove_foreign_key :daily_closes, :daily_closes_fk_ticker_id_tickers_id
  end
end

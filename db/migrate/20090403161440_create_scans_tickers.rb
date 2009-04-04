class CreateScansTickers < ActiveRecord::Migration
  def self.up
    create_table :scans_tickers, :id => false do |t|
      t.integer :ticker_id
      t.integer :scan_id
    end
  end

  def self.down
    drop_table :scans_tickers
  end
end

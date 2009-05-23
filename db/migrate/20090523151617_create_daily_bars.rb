class CreateDailyBars < ActiveRecord::Migration
  def self.up
    create_table :daily_bars, :options => "ENGINE=MyISAM", :force => true do |t|
      t.integer :ticker_id, :references => nil
      t.date :date
      t.float :open
      t.float :close
      t.float :high
      t.integer :volume
      t.float :logr
    end
  end

  def self.down
    drop_table :daily_bars
  end
end

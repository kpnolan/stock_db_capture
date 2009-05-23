class CreateIntraDayBars < ActiveRecord::Migration
  def self.up
    create_table :intra_day_bars, :options => "ENGINE=MyISAM", :force => true do |t|
      t.integer :ticker_id, :references => nil
      t.integer :interval
      t.datetime :start_time
      t.float :open
      t.float :close
      t.float :high
      t.integer :volume
      t.float :delta
    end
  end

  def self.down
    drop_table :intra_day_bars
  end
end

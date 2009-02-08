class CreateIsamLiveQuotes < ActiveRecord::Migration
  def self.up
    create_table(:live_quotes1, :options => 'ENGINE=MYISAM') do |t|
      t.integer  :ticker_id
      t.datetime :last_trade_time
      t.float    :last_trade
      t.float    :change_points
      t.float    :r
      t.float    :logr
      t.integer  :volume
    end
    add_index :live_quotes1, [ :ticker_id, :last_trade_time ], :unique => true
    LiveQuotes1.connection.execute('ALTER TABLE live_quotes1 ENGINE=MYISAM')
    Aggregate.connection.execute('ALTER TABLE aggregates ENGINE=MYISAM')
  end

  def self.down
    remove_index :live_quotes1
    drop_table :live_quotes1
  end
end


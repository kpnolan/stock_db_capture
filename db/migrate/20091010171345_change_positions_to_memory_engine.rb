class ChangePositionsToMemoryEngine < ActiveRecord::Migration
  def self.up
    create_table "btest_positions", :force => true, :options => 'ENGINE=MEMORY' do |t|
      t.integer  "ticker_id", :references => nil
      t.datetime "ettime"
      t.float    "etprice"
      t.float    "etival"
      t.datetime "xttime"
      t.float    "xtprice"
      t.float    "xtival"
      t.datetime "entry_date"
      t.float    "entry_price"
      t.float    "entry_ival"
      t.datetime "exit_date"
      t.float    "exit_price"
      t.float    "exit_ival"
      t.integer  "days_held"
      t.float    "nreturn"
      t.float    "logr"
      t.boolean  "short"
      t.boolean  "closed"
      t.integer  "entry_pass"
      t.float    "roi"
      t.integer  "num_shares"
      t.integer  "etind_id", :references => nil
      t.integer  "xtind_id", :references => nil
      t.integer  "entry_trigger_id", :references => nil
      t.integer  "entry_strategy_id", :references => nil
      t.integer  "exit_trigger_id", :references => nil
      t.integer  "exit_strategy_id", :references => nil
      t.integer  "scan_id", :references => nil
    end
    create_table "positions", :force => true do |t|
      t.integer  "ticker_id"
      t.datetime "ettime"
      t.float    "etprice"
      t.float    "etival"
      t.datetime "xttime"
      t.float    "xtprice"
      t.float    "xtival"
      t.datetime "entry_date"
      t.float    "entry_price"
      t.float    "entry_ival"
      t.datetime "exit_date"
      t.float    "exit_price"
      t.float    "exit_ival"
      t.integer  "days_held"
      t.float    "nreturn"
      t.float    "logr"
      t.boolean  "short"
      t.boolean  "closed"
      t.integer  "entry_pass"
      t.float    "roi"
      t.integer  "num_shares"
      t.integer  "etind_id", :references => :indicators
      t.integer  "xtind_id", :references => :indicators
      t.integer  "entry_trigger_id"
      t.integer  "entry_strategy_id"
      t.integer  "exit_trigger_id"
      t.integer  "exit_strategy_id"
      t.integer  "scan_id"
    end
    add_index :positions, [:ticker_id, :scan_id, :entry_strategy_id, :exit_strategy_id, :entry_date], :unique => true, :name => :unique_param_ids
    add_index :btest_positions, [:ticker_id, :scan_id, :entry_strategy_id, :exit_strategy_id, :entry_date], :unique => true, :name => :unique_param_ids
  end

  def self.down
    drop_table :btest_positions
    drop_table :positions
  end
end

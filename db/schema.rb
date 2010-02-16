# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100214213249) do

  create_table "contract_types", :force => true do |t|
    t.string "name"
  end

  create_table "current_listings", :force => true do |t|
    t.float   "moving_ave_50_days_change_percent_from"
    t.float   "weeks52_change_from_low"
    t.float   "weeks52_change_percent_from_low"
    t.float   "weeks52_range_low"
    t.float   "weeks52_range_high"
    t.float   "peg_ratio"
    t.float   "dividend_yield"
    t.float   "price_per_eps_estimate_current_year"
    t.float   "oneyear_target_price"
    t.float   "dividend_per_share"
    t.float   "short_ratio"
    t.float   "price_persales"
    t.float   "price_per_eps_estimate_next_year"
    t.float   "eps"
    t.float   "moving_ave_50_days"
    t.float   "price_perbook"
    t.date    "ex_dividend_date"
    t.float   "moving_ave_200_days"
    t.float   "book_value"
    t.float   "eps_estimate_current_year"
    t.float   "market_cap"
    t.float   "pe_ratio"
    t.float   "moving_ave_200_days_change_from"
    t.float   "eps_estimate_next_year"
    t.integer "ticker_id"
    t.float   "moving_ave_200_days_change_percent_from"
    t.float   "eps_estimate_next_quarter"
    t.date    "dividend_paydate"
    t.float   "weeks52_change_from_high"
    t.float   "moving_ave_50_days_change_from"
    t.float   "ebitda"
    t.float   "weeks52_change_percent_from_high"
  end

  create_table "daily_bars", :force => true do |t|
    t.integer  "ticker_id"
    t.float    "opening"
    t.float    "close"
    t.float    "high"
    t.integer  "volume"
    t.float    "low"
    t.datetime "bartime"
    t.float    "adj_close"
    t.date     "bardate"
    t.string   "source",    :limit => 1
  end

  add_index "daily_bars", ["ticker_id", "bartime"], :name => "index_daily_bars_on_ticker_id_and_bartime", :unique => true
  add_index "daily_bars", ["ticker_id", "bardate"], :name => "ticker_id_and_bardate", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "derived_value_types", :force => true do |t|
    t.string "name"
  end

  create_table "derived_values", :force => true do |t|
    t.integer  "ticker_id"
    t.integer  "derived_value_type_id"
    t.date     "date"
    t.datetime "time"
    t.float    "value"
  end

  add_index "derived_values", ["ticker_id"], :name => "ticker_id"
  add_index "derived_values", ["derived_value_type_id"], :name => "derived_value_type_id"

  create_table "entry_strategies", :force => true do |t|
    t.string "name"
    t.string "params"
    t.string "description"
  end

  create_table "entry_triggers", :force => true do |t|
    t.string "name"
    t.string "params"
    t.string "description"
  end

  create_table "exchanges", :force => true do |t|
    t.string "symbol"
    t.string "name"
    t.string "country"
    t.string "currency"
    t.string "timezone"
  end

  create_table "exit_strategies", :force => true do |t|
    t.string "name"
    t.string "params"
    t.string "description"
  end

  create_table "exit_triggers", :force => true do |t|
    t.string "name"
    t.string "params"
    t.string "description"
  end

  create_table "factors", :force => true do |t|
    t.integer "study_id"
    t.integer "indicator_id"
    t.string  "params_str"
    t.string  "result"
  end

  add_index "factors", ["study_id", "indicator_id", "result"], :name => "myfields_idx", :unique => true
  add_index "factors", ["indicator_id"], :name => "indicator_id"

  create_table "historical_attributes", :force => true do |t|
    t.string "name"
  end

  create_table "indicator_values", :force => true do |t|
    t.integer  "indicator_id"
    t.datetime "itime"
    t.float    "value"
    t.integer  "ticker_id"
    t.datetime "entry_date"
    t.integer  "valuable_id"
    t.string   "valuable_type", :limit => 64
  end

  create_table "indicators", :force => true do |t|
    t.string "name"
  end

  create_table "industries", :force => true do |t|
    t.string "name"
  end

  create_table "intra_day_bars", :force => true do |t|
    t.integer  "ticker_id"
    t.integer  "period"
    t.datetime "bartime"
    t.float    "opening"
    t.float    "close"
    t.float    "high"
    t.float    "low"
    t.integer  "volume"
    t.integer  "accum_volume"
    t.float    "delta"
    t.integer  "seq"
    t.date     "bardate"
  end

  add_index "intra_day_bars", ["ticker_id", "bartime"], :name => "ticker_id_and_start_time", :unique => true

  create_table "intra_snapshots", :force => true do |t|
    t.integer  "ticker_id"
    t.integer  "interval"
    t.datetime "snap_time"
    t.float    "open"
    t.float    "close"
    t.float    "high"
    t.float    "low"
    t.integer  "volume"
  end

  add_index "intra_snapshots", ["ticker_id"], :name => "ticker_id"

  create_table "ledger_txns", :force => true do |t|
    t.float    "amount"
    t.datetime "date"
    t.integer  "txn_type"
    t.integer  "order_id"
    t.float    "balance"
    t.string   "msg"
  end

  create_table "listing_categories", :id => false, :force => true do |t|
    t.integer "id",   :default => 0, :null => false
    t.string  "name"
  end

  create_table "memberships", :id => false, :force => true do |t|
    t.integer "id",                  :default => 0, :null => false
    t.integer "ticker_id"
    t.integer "listing_category_id"
  end

  create_table "mini_bar", :force => true do |t|
    t.integer  "ticker_id"
    t.float    "opening"
    t.float    "close"
    t.float    "high"
    t.integer  "volume"
    t.float    "low"
    t.datetime "bartime"
    t.float    "adj_close"
    t.date     "bardate"
    t.string   "source",    :limit => 1
  end

  add_index "mini_bar", ["ticker_id", "bartime"], :name => "index_daily_bars_on_ticker_id_and_bartime", :unique => true
  add_index "mini_bar", ["ticker_id", "bardate"], :name => "ticker_id_and_bardate", :unique => true

  create_table "orders", :force => true do |t|
    t.string   "txn",              :limit => 3, :null => false
    t.string   "otype",            :limit => 3, :null => false
    t.string   "expiration",       :limit => 3, :null => false
    t.integer  "quantity"
    t.datetime "placed_at"
    t.datetime "filled_at"
    t.float    "activation_price"
    t.float    "order_price"
    t.float    "fill_price"
    t.integer  "ticker_id",                     :null => false
    t.integer  "sim_position_id"
  end

  create_table "plot_attributes", :force => true do |t|
    t.string   "name"
    t.integer  "ticker_id"
    t.string   "type"
    t.datetime "anchor_date"
    t.integer  "period"
    t.string   "attributes"
  end

  add_index "plot_attributes", ["ticker_id"], :name => "ticker_id"

  create_table "plot_types", :force => true do |t|
    t.string  "name"
    t.string  "source_model"
    t.string  "method"
    t.string  "time_class"
    t.string  "resolution"
    t.string  "inputs"
    t.integer "num_outputs"
  end

  create_table "position_series", :force => true do |t|
    t.integer "position_id"
    t.integer "indicator_id"
    t.date    "date"
    t.float   "value"
  end

  create_table "positions", :id => false, :force => true do |t|
    t.integer  "ticker_id",         :default => 0, :null => false
    t.datetime "ettime"
    t.float    "etprice"
    t.float    "etival"
    t.datetime "xttime"
    t.float    "xtprice"
    t.float    "xtival"
    t.datetime "entry_date",                       :null => false
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
    t.integer  "etind_id"
    t.integer  "xtind_id"
    t.integer  "entry_trigger_id"
    t.integer  "entry_strategy_id"
    t.integer  "exit_trigger_id"
    t.integer  "exit_strategy_id"
    t.integer  "scan_id"
    t.float    "consumed_margin"
    t.integer  "eind_id"
    t.integer  "xind_id"
  end

  create_table "rsi_2000", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2000", ["factor_id"], :name => "factor_id"
  add_index "rsi_2000", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2001", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2001", ["factor_id"], :name => "factor_id"
  add_index "rsi_2001", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2002", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2002", ["factor_id"], :name => "factor_id"
  add_index "rsi_2002", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2003", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2003", ["factor_id"], :name => "factor_id"
  add_index "rsi_2003", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2004", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2004", ["factor_id"], :name => "factor_id"
  add_index "rsi_2004", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2005", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2005", ["factor_id"], :name => "factor_id"
  add_index "rsi_2005", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2006", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2006", ["factor_id"], :name => "factor_id"
  add_index "rsi_2006", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2007", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2007", ["factor_id"], :name => "factor_id"
  add_index "rsi_2007", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2008", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2008", ["factor_id"], :name => "factor_id"
  add_index "rsi_2008", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_2009", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "rsi_2009", ["factor_id"], :name => "factor_id"
  add_index "rsi_2009", ["ticker_id"], :name => "ticker_id"

  create_table "rsi_target_studies", :force => true do |t|
    t.integer "ticker_id"
    t.date    "start_date"
    t.date    "end_date"
    t.float   "delta_price"
    t.float   "slope"
    t.float   "chisq"
    t.float   "target_rsi"
    t.float   "prior_price"
    t.float   "last_price"
    t.float   "pos_delta"
    t.float   "neg_delta"
    t.float   "pos_delta_plus"
    t.float   "neg_delta_plus"
    t.float   "pos_delta_plus_ratio"
    t.float   "neg_delta_plus_ratio"
    t.float   "prior_rsi"
    t.float   "delta_rsi"
  end

  add_index "rsi_target_studies", ["ticker_id"], :name => "ticker_id"

  create_table "rsirvi_positions", :id => false, :force => true do |t|
    t.integer  "ticker_id",         :default => 0, :null => false
    t.datetime "ettime"
    t.float    "etprice"
    t.float    "etival"
    t.datetime "xttime"
    t.float    "xtprice"
    t.float    "xtival"
    t.datetime "entry_date",                       :null => false
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
    t.integer  "etind_id"
    t.integer  "xtind_id"
    t.integer  "entry_trigger_id"
    t.integer  "entry_strategy_id"
    t.integer  "exit_trigger_id"
    t.integer  "exit_strategy_id"
    t.integer  "scan_id"
    t.float    "consumed_margin"
    t.integer  "eind_id"
    t.integer  "xind_id"
  end

  create_table "rvig_positions", :id => false, :force => true do |t|
    t.integer  "ticker_id",         :default => 0, :null => false
    t.datetime "ettime"
    t.float    "etprice"
    t.float    "etival"
    t.datetime "xttime"
    t.float    "xtprice"
    t.float    "xtival"
    t.datetime "entry_date",                       :null => false
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
    t.integer  "etind_id"
    t.integer  "xtind_id"
    t.integer  "entry_trigger_id"
    t.integer  "entry_strategy_id"
    t.integer  "exit_trigger_id"
    t.integer  "exit_strategy_id"
    t.integer  "scan_id"
    t.float    "consumed_margin"
    t.integer  "eind_id"
    t.integer  "xind_id"
  end

  create_table "scans", :force => true do |t|
    t.string  "name"
    t.date    "start_date"
    t.date    "end_date"
    t.text    "conditions"
    t.string  "description"
    t.string  "join"
    t.string  "table_name"
    t.string  "order_by"
    t.integer "prefetch"
    t.integer "postfetch"
    t.integer "count"
  end

  create_table "scans_tickers", :id => false, :force => true do |t|
    t.integer "ticker_id"
    t.integer "scan_id"
  end

  add_index "scans_tickers", ["ticker_id"], :name => "ticker_id"
  add_index "scans_tickers", ["scan_id"], :name => "scan_id"

  create_table "sectors", :force => true do |t|
    t.string "name"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "session_id"

  create_table "sim_jobs", :force => true do |t|
    t.string   "user"
    t.string   "dir"
    t.string   "prefix"
    t.string   "position_table"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "output"
    t.string   "filter_predicate"
    t.string   "sort_by"
    t.float    "initial_balance"
    t.float    "order_amount"
    t.float    "minimum_balance"
    t.integer  "portfolio_size"
    t.float    "reinvest_percent"
    t.float    "order_charge"
    t.string   "entry_slippage"
    t.string   "exit_slippage"
    t.integer  "log_level"
    t.boolean  "keep_tables"
    t.datetime "job_started_at"
    t.datetime "job_finished_at"
  end

  create_table "sim_positions", :force => true do |t|
    t.datetime "entry_date"
    t.datetime "exit_date"
    t.integer  "quantity"
    t.float    "entry_price"
    t.float    "exit_price"
    t.float    "nreturn"
    t.float    "roi"
    t.integer  "days_held"
    t.integer  "eorder_id"
    t.integer  "xorder_id"
    t.integer  "ticker_id"
    t.date     "static_exit_date"
    t.integer  "position_id"
  end

  create_table "sim_summaries", :force => true do |t|
    t.date    "sim_date"
    t.integer "positions_held"
    t.integer "positions_available"
    t.float   "portfolio_value"
    t.float   "cash_balance"
    t.integer "pos_opened"
    t.integer "pos_closed"
  end

  create_table "snapshots", :force => true do |t|
    t.integer  "ticker_id"
    t.datetime "bartime"
    t.integer  "seq"
    t.float    "opening"
    t.float    "high"
    t.float    "low"
    t.float    "close"
    t.integer  "volume"
    t.integer  "accum_volume"
  end

  create_table "splits", :force => true do |t|
    t.integer "ticker_id"
    t.date    "date"
    t.integer "from"
    t.integer "to"
    t.date    "created_on"
  end

  add_index "splits", ["ticker_id", "date"], :name => "index_splits_on_ticker_id_and_date", :unique => true

  create_table "studies", :force => true do |t|
    t.string  "name"
    t.date    "start_date"
    t.date    "end_date"
    t.string  "description", :limit => 128
    t.integer "version"
    t.integer "sub_version"
    t.integer "iteration"
  end

  add_index "studies", ["name", "version", "sub_version", "iteration"], :name => "index_studies_on_name_and_version_and_sub_version_and_iteration", :unique => true

  create_table "study_results", :force => true do |t|
    t.integer "factor_id"
    t.date    "date"
    t.float   "value"
    t.integer "ticker_id"
  end

  add_index "study_results", ["factor_id"], :name => "factor_id"
  add_index "study_results", ["ticker_id"], :name => "ticker_id"

  create_table "ta_series", :force => true do |t|
    t.integer  "ticker_id"
    t.integer  "ta_spec_id"
    t.datetime "stime"
    t.float    "value"
    t.integer  "seq"
  end

  create_table "ta_specs", :force => true do |t|
    t.integer "indicator_id"
    t.integer "time_period"
  end

  add_index "ta_specs", ["indicator_id", "time_period"], :name => "indicator_id_and_time_period_idx", :unique => true

  create_table "temp_position_templates", :force => true do |t|
    t.integer "ticker_id"
    t.date    "ettime"
    t.float   "etprice"
    t.float   "etival"
    t.date    "xttime"
    t.float   "xtprice"
    t.float   "xtival"
    t.date    "entry_date"
    t.float   "entry_price"
    t.float   "entry_ival"
    t.float   "exit_price"
    t.date    "exit_date"
    t.float   "exit_ival"
    t.integer "days_held"
    t.float   "nreturn"
    t.integer "entry_pass"
    t.float   "roi"
    t.float   "consumed_margin"
    t.integer "volume"
  end

  add_index "temp_position_templates", ["ticker_id"], :name => "ticker_id"

  create_table "tickers", :force => true do |t|
    t.string  "symbol",      :limit => 8
    t.integer "exchange_id"
    t.boolean "active"
    t.integer "retry_count",              :default => 0
    t.string  "name"
    t.boolean "locked"
    t.boolean "etf"
    t.integer "sector_id"
    t.integer "industry_id"
    t.boolean "delisted",                 :default => false
  end

  add_index "tickers", ["symbol"], :name => "index_tickers_on_symbol", :unique => true
  add_index "tickers", ["id"], :name => "index_tickers_on_id_and_last_trade_time"
  add_index "tickers", ["sector_id"], :name => "sector_id"
  add_index "tickers", ["industry_id"], :name => "industry_id"
  add_index "tickers", ["name"], :name => "ticker_name_index"
  add_index "tickers", ["exchange_id"], :name => "exchange_id"

  create_table "watch_list", :force => true do |t|
    t.integer  "ticker_id"
    t.float    "rsi_target_price"
    t.float    "price"
    t.datetime "last_snaptime"
    t.integer  "num_samples"
    t.date     "listed_on"
    t.date     "closed_on"
    t.float    "opening"
    t.float    "high"
    t.float    "low"
    t.float    "close"
    t.integer  "volume"
    t.integer  "last_seq"
    t.float    "current_rsi"
    t.float    "current_rvi"
    t.float    "target_rsi"
    t.float    "target_rvi"
    t.datetime "open_crossed_at"
    t.datetime "closed_crossed_at"
    t.float    "min_delta"
    t.string   "nearest_indicator"
    t.date     "opened_on"
    t.float    "rvi_target_price"
    t.datetime "last_populate"
    t.float    "last_rsi"
    t.float    "closing_rsi"
    t.datetime "indicators_crossed_at"
  end

  add_index "watch_list", ["ticker_id"], :name => "ticker_id"

  create_table "yahoo_bars", :force => true do |t|
    t.integer  "ticker_id"
    t.float    "opening"
    t.float    "close"
    t.float    "high"
    t.integer  "volume"
    t.float    "low"
    t.datetime "bartime"
    t.float    "adj_close"
    t.date     "bardate"
  end

  add_index "yahoo_bars", ["ticker_id", "bartime"], :name => "ticker_id_and_bartime", :unique => true
  add_index "yahoo_bars", ["ticker_id", "bardate"], :name => "ticker_id_and_bardate", :unique => true

  add_foreign_key "derived_values", ["ticker_id"], "tickers", ["id"], :name => "derived_values_ibfk_1"
  add_foreign_key "derived_values", ["derived_value_type_id"], "derived_value_types", ["id"], :name => "derived_values_ibfk_2"

  add_foreign_key "factors", ["study_id"], "studies", ["id"], :name => "factors_ibfk_1"
  add_foreign_key "factors", ["indicator_id"], "indicators", ["id"], :name => "factors_ibfk_2"

  add_foreign_key "intra_snapshots", ["ticker_id"], "tickers", ["id"], :name => "intra_snapshots_ibfk_1"

  add_foreign_key "plot_attributes", ["ticker_id"], "tickers", ["id"], :name => "plot_attributes_ibfk_1"

  add_foreign_key "scans_tickers", ["ticker_id"], "tickers", ["id"], :name => "scans_tickers_ibfk_1"
  add_foreign_key "scans_tickers", ["scan_id"], "scans", ["id"], :name => "scans_tickers_ibfk_2"

  add_foreign_key "splits", ["ticker_id"], "tickers", ["id"], :name => "splits_ibfk_1"

  add_foreign_key "ta_specs", ["indicator_id"], "indicators", ["id"], :name => "ta_specs_ibfk_1"

  add_foreign_key "temp_position_templates", ["ticker_id"], "tickers", ["id"], :name => "temp_position_templates_ibfk_1"

  add_foreign_key "tickers", ["sector_id"], "sectors", ["id"], :name => "tickers_ibfk_1"
  add_foreign_key "tickers", ["industry_id"], "industries", ["id"], :name => "tickers_ibfk_2"
  add_foreign_key "tickers", ["exchange_id"], "exchanges", ["id"], :name => "tickers_ibfk_3"

  add_foreign_key "watch_list", ["ticker_id"], "tickers", ["id"], :name => "watch_list_ibfk_1"

end

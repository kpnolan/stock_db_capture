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

ActiveRecord::Schema.define(:version => 20090709170347) do

  create_table "bar_lookup", :force => true do |t|
  end

  add_index "bar_lookup", ["id"], :name => "id"

  create_table "contract_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer "ticker_id"
    t.date    "date"
    t.float   "open"
    t.float   "close"
    t.float   "high"
    t.integer "volume"
    t.float   "logr"
    t.float   "low"
  end

  add_index "daily_bars", ["ticker_id", "date"], :name => "index_daily_bars_on_ticker_id_and_date", :unique => true

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

  create_table "exchanges", :force => true do |t|
    t.string "symbol"
    t.string "name"
    t.string "country"
    t.string "currency"
    t.string "timezone"
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

  create_table "indicators", :force => true do |t|
    t.string "name"
  end

  create_table "industries", :force => true do |t|
    t.string "name"
  end

  create_table "intra_day_archives", :id => false, :force => true do |t|
    t.integer  "ticker_id"
    t.integer  "period"
    t.datetime "start_time"
    t.float    "open"
    t.float    "close"
    t.float    "high"
    t.float    "low"
    t.integer  "volume"
    t.integer  "accum_volume"
    t.float    "delta"
  end

  create_table "intra_day_bars", :force => true do |t|
    t.integer  "ticker_id"
    t.integer  "period"
    t.datetime "start_time"
    t.float    "open"
    t.float    "close"
    t.float    "high"
    t.float    "low"
    t.integer  "volume"
    t.integer  "accum_volume"
    t.float    "delta"
    t.integer  "seq"
  end

  add_index "intra_day_bars", ["ticker_id", "start_time"], :name => "ticker_id_and_start_time", :unique => true

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

  create_table "listing_categories", :force => true do |t|
    t.string "name"
  end

  create_table "memberships", :force => true do |t|
    t.integer "ticker_id"
    t.integer "listing_category_id"
  end

  create_table "nasdaq", :id => false, :force => true do |t|
    t.string "symbol", :limit => 8
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

  create_table "positions", :force => true do |t|
    t.integer  "ticker_id"
    t.datetime "entry_date"
    t.datetime "exit_date"
    t.float    "entry_price"
    t.float    "exit_price"
    t.integer  "num_shares"
    t.string   "stop_loss"
    t.integer  "strategy_id"
    t.integer  "days_held"
    t.float    "nreturn"
    t.integer  "scan_id"
    t.float    "entry_trigger"
    t.float    "exit_trigger"
    t.float    "logr"
    t.boolean  "short"
    t.integer  "pass"
    t.integer  "entry_pass"
  end

  add_index "positions", ["ticker_id", "entry_date"], :name => "pass_index", :unique => true
  add_index "positions", ["strategy_id"], :name => "strategy_id"
  add_index "positions", ["ticker_id"], :name => "index_positions_on_portfolio_id_and_ticker_id"
  add_index "positions", ["scan_id"], :name => "scan_id"

  create_table "positions_strategies", :id => false, :force => true do |t|
    t.integer "strategy_id"
    t.integer "position_id"
  end

  add_index "positions_strategies", ["strategy_id"], :name => "strategy_id"
  add_index "positions_strategies", ["position_id"], :name => "position_id"

  create_table "ref_positions", :force => true do |t|
    t.integer  "ticker_id"
    t.datetime "entry_date"
    t.datetime "exit_date"
    t.float    "entry_price"
    t.float    "exit_price"
    t.integer  "num_shares"
    t.string   "stop_loss"
    t.integer  "strategy_id"
    t.integer  "days_held"
    t.float    "nreturn"
    t.integer  "scan_id"
    t.float    "entry_trigger"
    t.float    "exit_trigger"
    t.float    "logr"
    t.boolean  "short"
    t.integer  "pass"
    t.integer  "entry_pass"
  end

  create_table "samples", :id => false, :force => true do |t|
    t.integer "ticker_id"
  end

  create_table "scans", :force => true do |t|
    t.string "name"
    t.date   "start_date"
    t.date   "end_date"
    t.text   "conditions"
    t.string "description"
    t.string "join"
    t.string "table_name"
    t.string "order_by"
  end

  create_table "scans_strategies", :id => false, :force => true do |t|
    t.integer  "scan_id"
    t.integer  "strategy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scans_strategies", ["scan_id"], :name => "scan_id"
  add_index "scans_strategies", ["strategy_id"], :name => "strategy_id"

  create_table "scans_tickers", :id => false, :force => true do |t|
    t.integer "ticker_id"
    t.integer "scan_id"
  end

  add_index "scans_tickers", ["ticker_id"], :name => "ticker_id"
  add_index "scans_tickers", ["scan_id"], :name => "scan_id"

  create_table "sectors", :force => true do |t|
    t.string "name"
  end

  create_table "snapshots", :force => true do |t|
    t.integer  "ticker_id"
    t.datetime "snaptime"
    t.integer  "seq"
    t.float    "open"
    t.float    "high"
    t.float    "low"
    t.float    "close"
    t.integer  "volume"
    t.integer  "accum_volume"
    t.integer  "secmid"
  end

  create_table "strategies", :force => true do |t|
    t.string "name"
    t.string "open_description"
    t.string "open_params_yaml"
    t.string "close_params_yaml"
    t.string "close_description"
  end

  add_index "strategies", ["name"], :name => "index_strategies_on_name", :unique => true

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

  create_table "symex", :id => false, :force => true do |t|
    t.string "symbol",      :limit => 8
    t.string "exchange_id"
  end

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
  end

  add_index "tickers", ["symbol"], :name => "index_tickers_on_symbol", :unique => true
  add_index "tickers", ["id"], :name => "index_tickers_on_id_and_last_trade_time"
  add_index "tickers", ["sector_id"], :name => "sector_id"
  add_index "tickers", ["industry_id"], :name => "industry_id"
  add_index "tickers", ["name"], :name => "ticker_name_index"
  add_index "tickers", ["exchange_id"], :name => "exchange_id"

  add_foreign_key "derived_values", ["ticker_id"], "tickers", ["id"], :name => "derived_values_ibfk_1"
  add_foreign_key "derived_values", ["derived_value_type_id"], "derived_value_types", ["id"], :name => "derived_values_ibfk_2"

  add_foreign_key "factors", ["study_id"], "studies", ["id"], :name => "factors_ibfk_1"
  add_foreign_key "factors", ["indicator_id"], "indicators", ["id"], :name => "factors_ibfk_2"

  add_foreign_key "intra_snapshots", ["ticker_id"], "tickers", ["id"], :name => "intra_snapshots_ibfk_1"

  add_foreign_key "plot_attributes", ["ticker_id"], "tickers", ["id"], :name => "plot_attributes_ibfk_1"

  add_foreign_key "positions", ["ticker_id"], "tickers", ["id"], :name => "positions_ibfk_2"
  add_foreign_key "positions", ["strategy_id"], "strategies", ["id"], :name => "positions_ibfk_3"
  add_foreign_key "positions", ["scan_id"], "scans", ["id"], :name => "positions_ibfk_4"

  add_foreign_key "positions_strategies", ["strategy_id"], "strategies", ["id"], :name => "positions_strategies_ibfk_1"
  add_foreign_key "positions_strategies", ["position_id"], "positions", ["id"], :name => "positions_strategies_ibfk_2"

  add_foreign_key "scans_strategies", ["scan_id"], "scans", ["id"], :name => "scans_strategies_ibfk_1"
  add_foreign_key "scans_strategies", ["strategy_id"], "strategies", ["id"], :name => "scans_strategies_ibfk_2"

  add_foreign_key "scans_tickers", ["ticker_id"], "tickers", ["id"], :name => "scans_tickers_ibfk_1"
  add_foreign_key "scans_tickers", ["scan_id"], "scans", ["id"], :name => "scans_tickers_ibfk_2"

  add_foreign_key "tickers", ["sector_id"], "sectors", ["id"], :name => "tickers_ibfk_1"
  add_foreign_key "tickers", ["industry_id"], "industries", ["id"], :name => "tickers_ibfk_2"
  add_foreign_key "tickers", ["exchange_id"], "exchanges", ["id"], :name => "tickers_ibfk_3"

end

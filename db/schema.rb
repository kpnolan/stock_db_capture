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

ActiveRecord::Schema.define(:version => 20081227191313) do

  create_table "aggregates", :force => true do |t|
    t.integer  "ticker_id"
    t.date     "date"
    t.datetime "start"
    t.float    "open"
    t.float    "close"
    t.float    "high"
    t.float    "low"
    t.integer  "volume"
    t.integer  "period"
  end

  add_index "aggregates", ["ticker_id"], :name => "ticker_id"

  create_table "aggregations", :force => true do |t|
    t.integer  "ticker_id",    :null => false
    t.date     "date"
    t.float    "open"
    t.float    "close"
    t.float    "high"
    t.float    "low"
    t.float    "adj_close"
    t.integer  "volume"
    t.integer  "week"
    t.integer  "month"
    t.integer  "sample_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "daily_closes", :force => true do |t|
    t.integer "ticker_id",  :null => false
    t.date    "date"
    t.float   "open"
    t.float   "close"
    t.float   "high"
    t.float   "low"
    t.float   "adj_close"
    t.integer "volume"
    t.integer "week"
    t.integer "month"
    t.float   "return"
    t.float   "log_return"
    t.float   "alr"
  end

  add_index "daily_closes", ["ticker_id", "date"], :name => "index_daily_closes_on_ticker_id_and_date", :unique => true

  create_table "exchanges", :force => true do |t|
    t.string "symbol"
    t.string "name"
    t.string "country"
    t.string "currency"
    t.string "timezone"
  end

  create_table "historical_attributes", :force => true do |t|
    t.string "name"
  end

  create_table "listing_categories", :force => true do |t|
    t.string "name"
  end

  create_table "listings", :force => true do |t|
    t.float   "moving_ave_50_days_change_percent_from"
    t.float   "weeks52_change_from_low"
    t.float   "weeks52_change_percent_from_low"
    t.float   "weeks52_range_low"
    t.float   "weeks52_range_high"
    t.float   "peg_ratio"
    t.float   "dividend_yield"
    t.string  "name"
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

  create_table "live_quotes", :force => true do |t|
    t.integer  "volume"
    t.float    "change_percent"
    t.float    "change_points"
    t.float    "last_trade"
    t.datetime "last_trade_time"
    t.integer  "ticker_id"
  end

  add_index "live_quotes", ["ticker_id", "last_trade_time"], :name => "index_live_quotes_on_ticker_id_and_last_trade_time", :unique => true

  create_table "memberships", :force => true do |t|
    t.integer "ticker_id"
    t.integer "listing_category_id"
  end

  create_table "real_time_quotes", :force => true do |t|
    t.float    "last_trade"
    t.float    "ask"
    t.float    "bid"
    t.datetime "last_trade_time"
    t.float    "change"
    t.float    "change_points"
    t.integer  "ticker_id"
  end

  create_table "shorts", :force => true do |t|
    t.string  "symbol", :limit => 8
    t.integer "count",  :limit => 8, :default => 0, :null => false
  end

  create_table "stat_values", :force => true do |t|
    t.integer  "historical_attribute_id"
    t.integer  "ticker_id"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "sample_count"
    t.float    "mean"
    t.float    "min"
    t.float    "max"
    t.float    "stddev"
    t.float    "absdev"
    t.float    "skew"
    t.float    "kurtosis"
    t.float    "slope"
    t.float    "yinter"
    t.float    "cov00"
    t.float    "cov01"
    t.float    "cov11"
    t.float    "chisq"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "cv"
  end

  create_table "tickers", :force => true do |t|
    t.string  "symbol",      :limit => 8
    t.string  "exchange_id"
    t.boolean "active"
  end

  add_index "tickers", ["symbol"], :name => "index_tickers_on_symbol"

  add_foreign_key "aggregates", ["ticker_id"], "tickers", ["id"], :name => "aggregates_ibfk_1"

end

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

ActiveRecord::Schema.define(:version => 20080812190631) do

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
    t.integer "ticker_id", :null => false
    t.date    "date"
    t.float   "open"
    t.float   "close"
    t.float   "high"
    t.float   "low"
    t.float   "adj_close"
    t.integer "volume"
    t.integer "week"
    t.integer "month"
  end

  create_table "daily_returns", :force => true do |t|
    t.integer  "volume"
    t.float    "ask"
    t.float    "bid"
    t.float    "day_range_low"
    t.float    "day_range_high"
    t.float    "change_percent"
    t.date     "last_trade_date"
    t.string   "tickertrend",     :limit => 7
    t.float    "change_points"
    t.float    "open"
    t.float    "previous_close"
    t.float    "last_trade"
    t.integer  "avg_volumn"
    t.float    "day_low"
    t.datetime "last_trade_time"
    t.float    "day_high"
    t.integer  "ticker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "real_time_quotes", :force => true do |t|
    t.float    "last_trade"
    t.float    "ask"
    t.float    "bid"
    t.datetime "last_trade_time"
    t.float    "change"
    t.float    "change_points"
    t.integer  "ticker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tickers", :force => true do |t|
    t.string "symbol",      :limit => 8
    t.string "exchange_id"
  end

  add_index "tickers", ["symbol"], :name => "index_tickers_on_symbol"

  create_table "tracking_event_types", :force => true do |t|
    t.string   "name",                 :null => false
    t.string   "notification_address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "value",                :null => false
    t.string   "abbrev",               :null => false
    t.string   "select_name"
  end

end

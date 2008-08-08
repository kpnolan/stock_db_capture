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

ActiveRecord::Schema.define(:version => 0) do

  create_table "exchanges", :force => true do |t|
    t.string "symbol"
    t.string "name"
    t.string "timezone"
  end

  create_table "listings", :force => true do |t|
    t.decimal "moving_ave_50_days_change_percent_from",                :precision => 8,  :scale => 2
    t.decimal "weeks52_change_from_low",                               :precision => 8,  :scale => 2
    t.decimal "weeks52_change_percent_from_low",                       :precision => 8,  :scale => 2
    t.decimal "weeks52_range_low",                                     :precision => 8,  :scale => 2
    t.decimal "weeks52_range_high",                                    :precision => 8,  :scale => 2
    t.decimal "peg_ratio",                                             :precision => 8,  :scale => 2
    t.decimal "dividend_yield",                                        :precision => 8,  :scale => 2
    t.string  "name"
    t.decimal "price_per_eps_estimate_current_year",                   :precision => 8,  :scale => 2
    t.decimal "oneyear_target_price",                                  :precision => 8,  :scale => 2
    t.decimal "dividend_per_share",                                    :precision => 8,  :scale => 2
    t.decimal "short_ratio",                                           :precision => 8,  :scale => 2
    t.decimal "price_persales",                                        :precision => 8,  :scale => 2
    t.decimal "price_per_eps_estimate_next_year",                      :precision => 8,  :scale => 2
    t.decimal "eps",                                                   :precision => 8,  :scale => 2
    t.decimal "moving_ave_50_days",                                    :precision => 8,  :scale => 2
    t.decimal "price_perbook",                                         :precision => 8,  :scale => 2
    t.date    "ex_dividend_date"
    t.decimal "moving_ave_200_days",                                   :precision => 8,  :scale => 2
    t.decimal "book_value",                                            :precision => 8,  :scale => 2
    t.decimal "eps_estimate_current_year",                             :precision => 8,  :scale => 2
    t.decimal "market_cap",                                            :precision => 10, :scale => 2
    t.decimal "pe_ratio",                                              :precision => 8,  :scale => 2
    t.decimal "moving_ave_200_days_change_from",                       :precision => 8,  :scale => 2
    t.decimal "eps_estimate_next_year",                                :precision => 8,  :scale => 2
    t.integer "ticker_id",                               :limit => 11
    t.decimal "moving_ave_200_days_change_percent_from",               :precision => 8,  :scale => 2
    t.decimal "eps_estimate_next_quarter",                             :precision => 8,  :scale => 2
    t.date    "dividend_paydate"
    t.decimal "weeks52_change_from_high",                              :precision => 8,  :scale => 2
    t.decimal "moving_ave_50_days_change_from",                        :precision => 8,  :scale => 2
    t.decimal "ebitda",                                                :precision => 10, :scale => 2
    t.decimal "weeks52_change_percent_from_high",                      :precision => 8,  :scale => 2
  end

  create_table "tickers", :force => true do |t|
    t.string "symbol",      :limit => 8
    t.string "exchange_id"
  end

  add_index "tickers", ["symbol"], :name => "index_tickers_on_symbol"

end

  #
  # 'Live' quote data retrieval.
  #

  stdhash = {
    "s" => [ "symbol", "val" ],
    "n" => [ "name", "val" ],
    "l1" => [ "last_trade", "val.to_f" ],
    "d1" => [ "date", "val" ],
    "t1" => [ "time", "val" ],
    "c" => [ "change", "val" ],
    "c1" => [ "change_points", "val.to_f" ],
    "p2" => [ "change_percent", "val.to_f" ],
    "p" => [ "previous_close", "val.to_f" ],
    "o" => [ "open", "val.to_f" ],
    "h" => [ "day_high", "val.to_f" ],
    "g" => [ "day_low", "val.to_f" ],
    "v" => [ "volume", "val.to_i" ],
    "m" => [ "day_range", "val" ],
    "l" => [ "last_trade_with_time", "val" ],
    "t7" => [ "tickertrend", "convert(val)" ],
    "a2" => [ "average_daily_volume", "val.to_i" ],
    "b" => [ "bid", "val.to_f" ],
    "a" => [ "ask", "val.to_f" ]
# These return integers like "1,000".  The CVS parser gets confused by this
# so I've removed them for the time being.
#    "b6" => [ "bidSize", "val" ],
#    "a5" => [ "askSize", "val" ],
#    "k3" => [ "lastTradeSize", "convert(val)" ],
  }

  EXTENDEDHASH = {
    "s" => [ "symbol", "val" ],
    "n" => [ "name", "val" ],
    "w" => [ "weeks_52_range", "val" ],
    "j5" => [ "weeks_52_change_from_low", "val.to_f" ],
    "j6" => [ "weeks52_change_percent_from_low", "val" ],
    "k4" => [ "weeks52_change_from_high", "val.to_f" ],
    "k5" => [ "weeks52_change_percent_from_high", "val" ],
    "e" => [ "eps", "val.to_f" ],
    "r" => [ "pe_ratio", "val.to_f" ],
    "s7" => [ "short_ratio", "val" ],
    "r1" => [ "dividend_paydate", "val" ],
    "q" => [ "ex_dividend_date", "val" ],
    "d" => [ "dividend_per_share", "convert(val)" ],
    "y" => [ "dividend_yield", "convert(val)" ],
    "j1" => [ "market_cap", "convert(val)" ],
    "t8" => [ "oneyear_target_price", "val" ],
    "e7" => [ "eps_estimate_current_year", "val" ],
    "e8" => [ "eps_estimate_next_year", "val" ],
    "e9" => [ "eps_estimate_next_quarter", "val" ],
    "r6" => [ "price_per_eps_estimate_current_year", "val" ],
    "r7" => [ "price_per_eps_estimate_next_year", "val" ],
    "r5" => [ "peg_ratio", "val.to_f" ],
    "b4" => [ "book_value", "val.to_f" ],
    "p6" => [ "price_perbook", "val.to_f" ],
    "p5" => [ "price_persales", "val.to_f" ],
    "j4" => [ "ebitda", "val" ],
    "m3" => [ "moving_ave_50_days", "val" ],
    "m7" => [ "moving_ave_50_days_change_from", "val" ],
    "m8" => [ "moving_ave_50_days_change_percent_from", "val" ],
    "m4" => [ "moving_ave_200_days", "val" ],
    "m5" => [ "moving_ave_200_days_change_from", "val" ],
    "m6" => [ "moving_ave_200_days_change_percent_from", "val" ],
    "w1" => [ "day_value_change", "val" ],
    "x" => [ "stock_exchange", "val" ]
# This returns an integer like "1,000,000".
# The CVS parser gets confused by this
# so I've removed it for the time being.
#    "f6" => [ "floatShares", "val" ],
  }

  REALTIMEHASH = {
    "s" => [ "symbol", "val" ],
    "n" => [ "name" , "val" ],
    "b2" => [ "ask", "val.to_f" ],
    "b3" => [ "bid", "val.to_f" ],
    "k2" => [ "change", "val" ],
    "k1" => [ "lastTradeWithTime", "val" ],
    "c6" => [ "changePoints", "val.to_f" ],
    "m2" => [ "dayRange", "val" ],
    "j3" => [ "marketCap", "convert(val)" ],
#      "v7" => [ "holdingsValue", "val" ],
#      "w4" => [ "dayValueChange", "val" ],
#      "g5" => [ "holdingsGainPercent", "val" ],
#      "g6" => [ "holdingsGain", "val" ],
#      "r2" => [ "pe", "val" ],
#      "c8" => [ "afterHoursChange", "val" ],
#      "i5" => [ "orderBook", "val" ],
  }

###################################################################################################
#
# This file specifies all of the requisite information to perform one backtest. The declarations
# serve the following purposes:
#
#   analytics - section which describes the conditions underwhich trades can occur. In this
#               block the following "verbs" are supported:
#       * open_position - describes the conditions underwhich a position will be openned.
#                         It takes three arguments:
#                           - the symbol name of this block, used as the means by which the
#                             information given is name, stored and retrieved fro the database.
#                           - the paramaters passed in to the block (the part that comes after the "do"
#                           - a block of ruby code that will get executed on every stock
#                             in the population to which is "verb" is applied.
#
#   populations - a section that describes the characteristics of named populations. In
#                 this block a set of "scans" are defined which determine characteristics
#                 of the population name.
#
#   backtests - this is where an association is made between an analytic component  and
#               the population to which that analysis is to be applied. The "verbs"
#               supported in this section are:
#       * apply - the declaration making the association beteen an analysis and
#                 a population. It takes three arguments:
#                   - the symbolic name of an anaylsis define in the "analytics"
#                     section.
#                   - the name of a population to which the analysis is to be
#                     applied.
#                   - a block of code which is executed for every DB record
#                     generated by applying the analysis to every timeseries
#                     in the specified population.
#
# In this example backtest specification, three analysis are defined, each with different
# criterion for openning a positiion. One population is defined which essentially describes
# all liquid stocks for the year 2008. One backtest is defined which opens positions
# when the conditions described for :rsi_oversold are met on all liquid stocks in 2008.
# Further, for each position openned, that position is closed by semantics of "close_at_max"
# which is a method which closes positions on the day of the close where the maximum ROI
# achievable withing the holding time of 1 to 10 trading days.
#
####################################################################################################

analytics do

  desc "Find all places where RSI gooes under 30"
  open_position :rsi_oversold, :threshold => 30, :time_period => 5 do |ts, params|
      memo = ts.rsi params.merge(:noplot => true, :result => :memo)
      memo.under_threshold(params[:threshold], :real)
  end

  desc "Find all places where the low of a day crosses below 2 std dev form the SMA(5)"
  open_position :bband_overshold, :time_period => 10, :deviations_up => 2.0, :deviations_down => 2.0 do |ts, params|
    memo = ts.bband params.merge(:noplot => true, :result => :memo)
    memo.crosses_under(:price, :lower_band)
  end

  desc "Find all date where Relative Volatility Index (RVI) is greater then 50"
  open_position :rvi, :time_period => 5, :threshold => 50  do |ts, params|
    memo = ts.rvi params.merge(:noplot => true, :result => :memo)
    memo.over_threshold(params[:threshold], :rvi)
  end
end

populations do
  liquid = 'min(volume) > 100000 and count(*) > 100'
  year = 8
  desc "Population of all stocks with a minimum value of 100000 and at least100 days traded in #{2000+year}"
  scan "liquid_#{2000+year}", :start_date => "06/01/#{2000+year-1}", :end_date => "12/31/#{2000+year}", :conditions => liquid
end

backtests(:price => :close) do
  apply(:rsi_oversold, :liquid_2008) do |position|
#    position.close_at_max(:hold_time => 1..10)
#    position.close_at_days_held(10)
    position.close_at(:indicator => :rsi, :max_days_held => 21, :params => { :threshold => 70, :time_period => 5})
  end
#  apply(:rsi_oversold2, :test_msft) do |position|
#    position.close_at(:indicator => :rsi, :params => { :threshold => 70, :time_period => 5})
#  end
end

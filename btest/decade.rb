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
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_rvi, :time_period => 14 do |params, pass|
    rsi_ary = rsi(params.merge(:noplot => true, :result => :raw)).first
    indexes = under_threshold(20+pass*5, rsi_ary)
    indexes.map do |index|
      #pslope = linreg(index-5, :time_period => 5, :noplot => true)
      eslope = linreg(index, :time_period => 5, :noplot => true)
      #cslope = case pass
      #         when 0: pslope * -0.2419 + 0.1804
      #         when 1: pslope * -0.4062 + 0.1060
      #         when 2: pslope * -0.3369 + 0.2260
      #         end
      idx = eslope > 0.02 ? index : nil
      #{ :index => idx, :pslope => pslope, :eslope => eslope, :cslope => cslope }
    end
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :rsi_rvi, :time_period => 14 do |params|
    params.reverse_merge! :noplot => true, :result => :raw
    rsi_ary = rsi(params).first
    rvi_ary = rvi(params).first
    rsi_idx = under_threshold(50, rsi_ary).first
    rvi_idx = under_threshold(40, rvi_ary).first

    [rsi_idx, rvi_idx].min do |a,b|
      case
      when a && b : a <=> b
      when a.nil? && b : 1
      when b.nil? && a : -1
      else 0
      end
    end
  end

  desc "Close the position if the stop loss is 1% or greater"
  #stop_loss(20.0) #don't have intraday!!!!
end

populations do
  $names = []
  for year in [ 2008 ]
    name = "liquid_#{year}"
    liquid = "min(volume) > 100000 and count(*) = #{trading_count_for_year(year)}"
    desc "Population of all stocks with a minimum valume of 100000 and have #{trading_count_for_year(year)} days traded in #{year}"
    scan name, :start_date => "01/01/#{year}", :end_date => "12/31/#{year}", :conditions => liquid
    $names << name
  end
end

backtests(:price => :close, :epass => 0..2) do
  apply(:rsi_rvi, :liquid_2008) do
#    make_sheet()
  end
end

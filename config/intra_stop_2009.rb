analytics do
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :intra_rsi_rvi, :time_period => 14 do |params, pass|
    rsi_ary = rsi(params.merge(:noplot => true, :result => :raw)).first
    indexes = under_threshold(20+pass*5, rsi_ary)
    #indexes.map do |start_index|
    #  slope = linreg(start_index, :time_period => 10*13, :noplot => true)
    #  slope > 0.02 ? start_index : nil
    #end
    indexes
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :intra_rsi_rvi, :time_period => 14 do |params, pass|
    params.reverse_merge! :noplot => true, :result => :raw
    rsi_ary = rsi(params).first
    rvi_ary = rvi(params).first
    rsi_idx = under_threshold(60-pass*5, rsi_ary).first
    rvi_idx = under_threshold(50-pass*5, rvi_ary).first

    case
    when rsi_idx.nil? && rvi_idx : rvi_idx
    when rsi_idx && rvi_idx : rsi_idx < rvi_idx ? rsi_idx : rvi_idx
    when rvi_idx.nil? : nil
    when rvi_idx : rvi_idx
    when rsi_idx : rsi_idx
    end
  end

  desc "Close the position if the stop loss is 1% or greater"
  stop_loss(25.0)

end

populations do
  name = "intraday_2009"
  start_date = Date.parse('2/2/2009')
  end_date = Date.parse('5/30/2009')
  liquid = "min(accum_volume) > 100000 and count(*) = #{total_bars(start_date, end_date, 13)}"
  desc "Population of all stocks with a minimum valume of 100000 and have  #{total_bars(start_date, end_date, 13)} bars"
  scan name, :table_name => 'intra_day_bars', :start_date => start_date, :end_date => end_date, :conditions => liquid
end

backtests(:price => :close, :resolution => 30.minutes, :close_buffer => 30) do
  apply(:intra_rsi_rvi, :intraday_2009) do
#    make_test()
  end
end

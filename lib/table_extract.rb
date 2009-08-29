# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module TableExtract

  include TradingCalendar

  def simple_vector(ticker, attr, start, period)
    ticker_id = normalize_ticker(ticker)
    start = start.send(time_convert)
    end_date = start + period
    connection.select_values("SELECT #{attr.to_s} FROM #{to_s.tableize} WHERE ticker_id = #{ticker_id} AND "+
                             "#{time_col} >= '#{start.to_s(:db)}' AND #{time_col} <= '#{end_date.to_s(:db)}' ORDER BY #{order}")
  end

  def time_vector(ticker, start_date, end_date)
    ticker_id = normalize_ticker(ticker)
    connection.select_values("SELECT #{time_col} FROM #{to_s.tableize} WHERE " + form_conditions(ticker_id, start_date, end_date))
  end

  def simple_vectors(ticker, attrs=[], start=nil, num_points=nil)
    bdate = start.send(time_convert)
    recs = find(:all, :conditions => form_conditions(ticker, bdate), :order => order, :limit => num_points)
    form_result_hash(recs, attrs)
  end

  def general_vectors_by_interval(ticker, attrs, bdate, period)
    bdate = bdate.send(time_convert)
    edate = bdate + period
    recs = find(:all, :conditions => form_conditions(ticker, bdate, edate), :order => order)
    form_result_hash(recs, attrs)
  end

  def general_vectors(ticker, attrs, btime, etime)
    recs = find(:all, :conditions => form_conditions(ticker, btime, etime), :order => order)
    form_result_hash(recs, attrs)
  end

  def form_result_hash(recs, attrs=[])
    return { } if recs.empty?
    result = { }
    attrs = [ attrs ] if attrs.class != Array
    attrs = (attrs == [] ? content_columns.collect!(&:name) : attrs)
    attrs.each { |attr| result[attr.to_sym] = recs.collect(&attr) }
    result
  end

  def find_last_close(ticker_id, date)
    rows = connection.select_rows("select date, close from #{table_name} where ticker_id = #{ticker_id} and date < '#{date.to_s(:db)}' order by date desc limit 1")
    rows.first
  end


  def normalize_ticker(ticker)
    case
    when ticker.is_a?(Fixnum) : ticker_id = ticker
    when ticker.is_a?(Symbol) : ticker_id = Ticker.find_by_symbol(ticker.to_s.upcase).id
    when ticker.is_a?(String) : ticker_id = Ticker.find_by_symbol(ticker.upcase).id
    else
      raise ArgumentError, 'ticker should be Fixnum or String'
    end
  end

  def form_conditions(ticker, btime, etime)
    ticker_id = normalize_ticker(ticker)
    bdate = btime.to_date
    edate = etime.to_date
    #
    # Tack on a extra day for the range to account for the way MySQL treats intraday betweens, i.e.
    # between give you one day of intraday for 2 between days
    #
    if self.name == 'IntraDayBar'
      bdate = trading_date_from(bdate, -1) unless trading_day?(bdate)
      edate = trading_date_from(edate, 1)
    end
    "ticker_id = #{ticker_id} AND #{time_col} BETWEEN '#{bdate.to_s(:db)}' AND '#{edate.to_s(:db)}' "
  end
end

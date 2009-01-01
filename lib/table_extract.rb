module TableExtract

  def simple_vector(ticker, attr, start, period)
    ticker_id = normalize_ticker(ticker)
    start = start.send(time_convert)
    end_date = start + period
    connection.select_values("SELECT #{attr.to_s} FROM #{to_s.tableize} WHERE ticker_id = #{ticker_id} AND "+
                             "#{time_col} >= '#{start.to_s(:db)}' AND #{time_col} <= '#{end_date.to_s(:db)}' ORDER BY #{order}")
  end

  def simple_vectors(ticker, attrs=[], start=nil, num_points=nil)
    recs = find(:all, :conditions => form_conditions(ticker, start), :order => order, :limit => num_points)
    form_result_hash(recs, attrs)
  end

  def general_vectors(ticker, attrs, bdate, period)
    bdate = bdate.send(time_convert)
    edate = bdate + period
    recs = find(:all, :conditions => form_conditions(ticker, bdate, edate), :order => order)
    form_result_hash(recs, attrs)
  end

  def form_result_hash(recs, attrs=[])
    result = { }
    attrs = [ attrs ] if attrs.class != Array
    attrs = (attrs == [] ? content_columns.collect!(&:name) : attrs)
    attrs.each { |attr| result[attr.to_sym] = recs.collect(&attr) }
    result
  end

  def normalize_ticker(ticker, bdate=nil, edate=nil)
    case
    when ticker.class == Fixnum : ticker_id = ticker
    when ticker.class == Symbol : ticker_id = Ticker.find_by_symbol(ticker.to_s.upcase).id
    when ticker.class == String : ticker_id = Ticker.find_by_symbol(ticker.upcase).id
    else
      raise ArgumentError, 'ticker should be Fixnum or String'
    end
  end

  def form_conditions(ticker, bdate=nil, edate=nil)
    ticker_id = normalize_ticker(ticker)
    case
    when bdate && edate   : [ "ticker_id = ? AND #{time_col} >= ? AND #{time_col} <= ?", ticker_id, bdate, edate ]
    when bdate            : [ "ticker_id = ? AND #{time_col} >= ? ", ticker_id, bdate]
    when edate            : [ "ticker_id = ? AND #{time_col} <= ?" , ticker_id, edate]
    else                    [ "ticker_id = ?", ticker_id ]
    end
  end
end

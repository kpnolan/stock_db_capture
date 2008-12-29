module TableExtract
  def get_vectors(ticker, attrs=[], bdate=nil, period=nil)
    case
    when ticker.class == Fixnum : ticker_id = ticker
    when ticker.class == Symbol : ticker_id = Ticker.find_by_symbol(ticker.to_s.upcase).id
    when ticker.class == String : ticker_id = Ticker.find_by_symbol(ticker.upcase).id
    else
      raise ArgumentError, 'ticker should be Fixnum or String'
    end

    edate = bdate + period

    dc = find(:all, :conditions => form_conditions(ticker_id, bdate, edate), :order => order)
    result = { }
    attrs = [ attrs ] if attrs.class != Array
    attrs = (attrs == [] ? content_columns.collect!(&:name) : attrs)
    attrs.each { |attr| result[attr.to_sym] = dc.collect(&attr) }

    return result
  end

  def form_conditions(id, bdate, edate)
    case
    when bdate && edate   : [ "ticker_id = ? AND date >= ? AND date <= ?", id, bdate, edate ]
    when bdate            : [ "ticker_id = ? AND date >= ? ", id, bdate]
    when edate            : [ "ticker_id = ? AND date <= ?" , id, edate]
    else                    [ "ticker_id = ?", id ]
    end
  end
end

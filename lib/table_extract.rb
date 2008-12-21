module TableExtract
  def get_vectors(ticker, attrs=[], bdate=nil, edate=nil)
    case
    when ticker.class == Fixnum : ticker_id = ticker
    when ticker.class == Symbol : ticker_id = Ticker.find_by_symbol(ticker.to_s.upcase).id
    when ticker.class == String : ticker_id = Ticker.find_by_symbol(ticker.upcase).id
    else
      raise ArgumentError, 'ticker should be Fixnum or String'
    end

    dc = find(:all, :conditions => form_conditions(ticker_id, bdate, edate), :order => order)
    result = { }
    attrs = [ attrs ] if attrs.class != Array
    attrs = (attrs == [] ? default_attrs() : attrs)
    attrs.each { |attr| result[attr.to_sym] = dc.collect(&attr) }

    return result
  end

  def form_conditions(id, bdate, edate)
    case
    when bdate && edate   : [ 'ticker_id = ? AND date >= ? AND date <= ?', id, bdate.to_date, edate.to_date ]
    when bdate            : [ 'ticker_id = ? AND date >= ? ', id, bdate.to_date ]
    when edate            : [ 'ticker_id = ? AND date <= ?' , id, edate.to_date ]
    else                    [ 'ticker_id = ?', id ]
    end
  end
end

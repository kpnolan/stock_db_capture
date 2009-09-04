# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module TableExtract

  extend TradingCalendar

  def time_vector(ticker, start_date, end_date)
    ticker_id = ticker_id(ticker)
    recs = find.all(:conditions => form_conditions(ticker_id, start_date, end_date), :select => :bartime, :order => :bartime)
    recs.map(&:bartime)
  end

  def general_vectors(ticker, attrs, btime, etime)
    recs = find(:all, :conditions => form_conditions(ticker, btime, etime), :order => :bartime)
    form_result_hash(recs, attrs)
  end


  def form_result_hash(recs, attrs=[])
    return { } if recs.empty?
    result = { }
    attrs = [ attrs ] if attrs.class != Array
    attrs = (attrs.empty? ? content_columns.collect!(&:name) : attrs)
    # This mode of extraction (via attrs) actually proved to be faster than calling the direct method (via method call)
    attrs.each { |attr| result[attr.to_sym] = recs.collect { |rec| rec[attr] } }
    result
  end

  def find_last_close(ticker_id, date)
    last_close = find.first(:conditions => [ "ticker_id => ? and date(bartime) < ?", ticker_id, date ],
                            :select => [:bartime, :close], :group => :bartime, :having => "max(bartime)",
                            :order => 'bartime, desc', :limit => 1)
    last_close ? [last_close.bartime, last_close.close ] : []
  end


  def ticker_id(ticker)
    case ticker
    when Fixnum         : ticker
    when String         : Ticker.lookup(ticker).id
    when Symbol         : Ticker.lookup(ticker).id
    else
      raise ArgumentError, "ticker is a #{ticker.class}, should be Fixnum or String"
    end
  end

  def form_conditions(ticker, btime, etime)
    ticker_id = ticker_id(ticker)
    #
    # Tack on a extra day for the range to account for the way MySQL treats intraday betweens, i.e.
    # between give you one day of intraday for 2 between days (exclusive range instead of inclusive)
    #
    { :ticker_id => ticker_id, :bartime => btime..(etime.end_of_day) }
  end
end

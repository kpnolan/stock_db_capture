#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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
    when Fixnum         then ticker
    when String         then Ticker.lookup(ticker).id
    when Symbol         then Ticker.lookup(ticker).id
    else
      raise ArgumentError, "ticker is a #{ticker.class}, should be Fixnum or String"
    end
  end

  def form_conditions(ticker, btime, etime); { :ticker_id => ticker_id(ticker), :bartime => btime..(etime.end_of_day) };  end
end

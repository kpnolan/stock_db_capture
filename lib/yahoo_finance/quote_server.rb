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

require 'yahoo_finance/yahoofinance'

module YahooFinance

  COLUMN_ORDER = [ :date, :opening, :high, :low,  :close, :volume, :adj_close ]
  TYPE_ORDER =   [ :to_s, :to_f, :to_f, :to_f, :to_f,  :to_i,   :to_f]

  class QuoteServer

    attr_reader :options

    def initialize(options={})
      @options = options
    end

    def dailys_for(symbol, start_date, end_date, options={})
      ybars = YahooFinance.get_historical_quotes( symbol, start_date, end_date, 'd' )
      returning [] do |table|
        ybars.each do |ybar|
          type_vec = TYPE_ORDER.dup
          table << ybar.map! { |el| el.send(type_vec.shift) }
        end
      end
    end
  end
end

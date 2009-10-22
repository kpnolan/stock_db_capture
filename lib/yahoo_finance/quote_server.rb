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

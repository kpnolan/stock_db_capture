require 'yahoo_finance/yahoofinance'

module YahooFinance
  class QuoteServer

    attr_reader :options

    def initialize(options={})
      @options = options
    end

    def dailys_for(symbol, start_date, end_date, options={})
      ybars = YahooFinance.get_historical_quotes( symbol, start_date, end_date, 'd' )
      puts ybars.join(', ') if options[:debug]
      ybars
    end
  end
end

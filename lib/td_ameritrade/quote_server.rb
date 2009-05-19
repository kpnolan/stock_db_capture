require "uri"
require "net/https"

require 'tda2ruby'
require 'rubygems'
require 'ruby-debug'

module TdAmeritrade

  MINUTE = 1
  DAY = 2
  URL = 'https://apis.tdameritrade.com/apps/100/PriceHistory'

  class QuoteServer

    include Tda2Ruby
    include Net

    attr_reader :options, :bars, :interval_type, :frequency, :symbol, :start_date, :end_date
    attr_reader :response, :body

    def initialize(options={})
      options.reverse_merge! :login => 'LWSG', :source => :file, :filename => 'PriceHistory(4)', :dir => '/home/kevin/Downloads'
      @options = options
      @bars = []
      @interval_type = nil
      @frequency = nil
      @symbol = nil
    end

    def test
      dailys_for('IBM', Date.parse('01/01/2009'), Date.parse('03/31/2009'))
    end

    def dailys_for(symbol, start_date, end_date)
      quote_for(symbol, start_date, end_date, TdAmeritrade::DAY, 1)
    end

    def intraday_for(symbol, start_date, end_date, minute_resolution)
      quote_for(symbol, start_date, end_date, TdAmeritrade::MINUTE, minute_resolution)
    end

    def quote_for(symbol, start_date, end_date, period, resolution)
      validate_resolution(period, resolution)
      @symbol = symbol
      @start_date = start_date
      @end_date = end_date
      submit_request()
    end

    def submit_request
      uri = URI.parse(TdAmeritrade::URL)
      debugger
      begin
       @response, @body = HTTP.post_form(URI.parse(TdAmeritrade::URL),
        { 'source' => options[:login], 'requestvalue' => symbol, 'requestidentifiertype' => 'SYMBOL',
          'intervaltype' => interval_type, 'intervalduration' => frequency,
          'start_date' => start_date.to_s(:db), 'end_date' => end_date.to_s(:db) })
      rescue Exception => e
        puts "Exception return from submit: #{e.to_s}"
      end
      debugger
    end

    def validate_resolution(period, resolution)
      if period = TdAmeritrade::DAY
        @interval_type = 'DAILY'
        @frequency = 1
      elsif period = TdAmeritrade::MINUTE
        @interval_type = 'MINUTE'
        if [1, 5, 10, 15, 30].include? resolution
          @frequency = resolution
        else
          raise ArgumentError('If Intraday, resolution can only be 1, 5, 10, 15, 30 or minutes')
        end
      else
        raise ArgumentError("Unknown period of #{period}")
      end
    end

    def retrieve_quotes_from_file()
      GC.disable
      buff = IO.read(File.join(options[:dir], options[:filename]))
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bars.push(bar_ary)
      end
      GC.start
      for bar in bars
        puts %Q(#{bar.join("\t")})
      end
      debugger
      nil
    end
  end
end



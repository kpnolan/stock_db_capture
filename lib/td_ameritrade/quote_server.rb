require "uri"
require "net/https"

require 'tda2ruby'
require 'rubygems'
require 'ruby-debug'

module TdAmeritrade

  MINUTE = 1
  DAY = 2
  URL = 'https://apis.tdameritrade.com/apps/100/PriceHistory'

  #
  # Responsible for getting quotes from the TDAmeritrade PriceHistory server
  # the main methods:
  #   dailys_for(...)
  #   intraday_for(...)
  # return an 6 element arrary of the following order:
  #   [ close, high, low, open, volume, timestamp ]
  #
  # the volume element is not-cumulative, i.e. it represents the volume for that period not the sum
  # of the valumes upto that period.
  #
  # It appears that daily data is available after 11pm ET. Intraday data is available for 6 months.
  #
  class QuoteServer

    include Tda2Ruby
    include Net

    attr_reader :options, :bars, :interval_type, :frequency, :symbol, :start_date, :end_date
    attr_reader :response, :body

    def initialize(options={})
      options.reverse_merge! :login => 'LWSG'
      @options = options
      @bars = []
      @interval_type = nil
      @frequency = nil
      @symbol = nil
    end

    def test
      buff = intraday_for('SKF', Date.parse('05/19/2009'), Date.parse('05/19/2009'), 30)
      #buff = dailys_for('IBM', Date.parse('05/01/2009'), Date.parse('05/19/2009'))
      GC.disable
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bars.push(bar_ary)
      end
      GC.enable
      for bar in bars
        puts %Q(#{bar.join("\t")})
      end
    end

    def dailys_for(symbol, start_date, end_date)
      quote_for(symbol, start_date, end_date, TdAmeritrade::DAY, 1)
      buff = quote_for(symbol, start_date, end_date, TdAmeritrade::MINUTE, minute_resolution)
      GC.disable
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bar_ary[5] += 1.day
        bars.push(bar_ary)
      end
      GC.enable
      bars
    end

    def intraday_for(symbol, start_date, end_date, minute_resolution)
      buff = quote_for(symbol, start_date, end_date, TdAmeritrade::MINUTE, minute_resolution)
      GC.disable
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bars.push(bar_ary)
      end
      GC.enable
      bars
    end

    def quote_for(symbol, start_date, end_date, period, resolution)
      validate_resolution(period, resolution)
      @symbol = symbol
      @start_date = start_date
      @end_date = end_date
      submit_request()
    end

    def submit_request
      url = URI.parse(TdAmeritrade::URL)
      req = HTTP::Post.new(url.path)
      form_data = { 'source' => options[:login], 'requestvalue' => symbol, 'requestidentifiertype' => 'SYMBOL',
        'intervaltype' => interval_type, 'intervalduration' => frequency,
        'startdate' => start_date.to_s(:db).delete("-"), 'enddate' => end_date.to_s(:db).delete("-") }
      req.set_form_data(form_data)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      #http.set_debug_output($stderr)
      res = http.start { http.request(req) }

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return res.body
      else
        res.error!
      end
    end

    def validate_resolution(period, resolution)
      if period == TdAmeritrade::DAY
        @interval_type = 'DAILY'
        @frequency = 1
      elsif period == TdAmeritrade::MINUTE
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



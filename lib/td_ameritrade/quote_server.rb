require "uri"
require "net/https"
require 'xmlsimple'

require 'tda2ruby'
require 'rubygems'
require 'ruby-debug'

module TdAmeritrade

  MINUTE = 1
  DAY = 2
  URL = 'https://apis.tdameritrade.com/apps/100/PriceHistory'
  LOGIN_URL = 'https://apis.tdameritrade.com/apps/100/LogIn'
  LOGOUT_URL = 'https://apis.tdameritrade.com/apps/100/LogOut'
  STREAMER_INFO = 'https://apis.tdameritrade.com/apps/100/StreamerInfo'
  LOGIN = 'lewissternberg'
  PASSWORD = 'Troika3'
  MINUTES_PER_DAY = 390

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

    attr_reader :ioptions, :bars, :interval_type, :frequency
    attr_reader :response, :body, :login_xml, :cdi, :company, :segment, :account_id, :cookies, :token, :acl
    attr_reader :access_level, :app_id, :streamer_url

    def initialize(options={})
      options.reverse_merge! :login => 'LWSG'
      @ioptions = options
      @bars = []
      @interval_type = nil
      @frequency = nil
    end

    def test
      bars = intraday_for('JAVA', Date.parse('01/03/2009'), Date.parse("01/05/2009"), 30, :debug => true)
#      for bar in bars
#        puts %Q(#{bar.join("\t")})
#      end
      nil
    end

    def attach_to_streamer
      buff = login(:debug => true)
      credentials = XmlSimple.xml_in(buff)
      @login_xml = credentials['xml-log-in'].first
      parse_login_xml(login_xml)
      streamer_xml = streamer_info()
      parse_streamer_info(streamer_xml)
      debugger
      a = 1
    end

    def parse_login_xml(h)
      @cdi = h['cdi'].first
      @userid = h['user-id'].first
      @session_id = h['session-id'].first
      act = h['accounts'].first['account'].first
      @company = act['company'].first
      @segment = act['segment'].first
      @account_id = act['account-id'].first
    end

    def parse_streamer_info(xml)
      h = XmlSimple.xml_in(xml)
      si = h['streamer-info'].first
      @token = si['token'].first
      @access_level = si['access-level'].first
      @app_id = si['app-id'].first
      @acl = si['acl'].first
      @streamer_url = ['streamer-url'].first
    end

    def dailys_for(symbol, start_date, end_date, options={})
      buff = quote_for(symbol, start_date, end_date, TdAmeritrade::DAY, 1, options)
      GC.disable
      @bars = []
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bar_ary[5] += 1.day
        bars.push(bar_ary)
      end
      GC.enable
      bars
    end

    def intraday_for(symbol, start_date, end_date, minute_resolution, options={})
      buff = quote_for(symbol, start_date, end_date, TdAmeritrade::MINUTE, minute_resolution, options)
      GC.disable
      @bars = []
      symbol_count, symbol, bar_count = parse_header(buff)
      bar_count.times do
        bar_ary = parse_bar(buff)
        bars.push(bar_ary)
      end
      GC.enable
      bars
    end

    def quote_for(symbol, start_date, end_date, period, resolution, options={})
      validate_resolution(period, resolution)
      submit_quote_request(symbol, start_date, end_date, options)
    end

    def login(options={})
      url = URI.parse(TdAmeritrade::LOGIN_URL)
      req = HTTP::Post.new(url.path)
      form_data = { 'source' => ioptions[:login], 'userid' => TdAmeritrade::LOGIN, 'password' => TdAmeritrade::PASSWORD, 'version' => '1.0'}
      submit_request(TdAmeritrade::LOGIN_URL, form_data, options)
    end

    def streamer_info(options={})
      url = URI.parse(TdAmeritrade::STREAMER_INFO)
      form_data = { 'source' => ioptions[:login], 'accountid' => account_id }
      submit_request(TdAmeritrade::STREAMER_INFO, form_data, :debug => true)
    end

    def logout(options={})
      url = URI.parse(TdAmeritrade::LOGOUT_URL)
      req = HTTP::Post.new(url.path)
      form_data = { 'source' => ioptions[:login] }
      submit_request(TdAmeritrade::LOGOUT_URL, form_data, options)
    end

    def submit_request(uri, form_data, options)
      url = URI.parse(uri)
      req = HTTP::Post.new(url.path)
      req.add_field('Cookie', cookies)
      req.set_form_data(form_data)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.set_debug_output($stderr) if options[:debug]
      res = http.start { http.request(req) }

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @cookies = res['Set-Cookie']
        return res.body
      else
        res.error!
      end
    end

    def submit_quote_request(symbol, start_date, end_date, options={})
      form_data = { 'source' => ioptions[:login], 'requestvalue' => symbol, 'requestidentifiertype' => 'SYMBOL',
        'intervaltype' => interval_type, 'intervalduration' => frequency,
        'startdate' => start_date.to_s(:db).delete("-"), 'enddate' => end_date.to_s(:db).delete("-") }
      form_data['extended'] = 'true' if options[:extended]
      response = submit_request(TdAmeritrade::URL, form_data, options)
    end

    def submit_snapshot(symbol_list)

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



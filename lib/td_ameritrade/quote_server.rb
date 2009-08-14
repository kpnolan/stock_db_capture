# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require "uri"
require "net/https"
require 'xmlsimple'
require 'zlib'

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
  ACCOUNT = 781467570
  DAY2SEC = 24*60*60
  PASSWORD = 'Troika3'
  MINUTES_PER_DAY = 390
  SNAPSHOT_INTERVAL = 0
  STREAMER_ORDER = [ :U, :W, :A, :token, :company, :segment, :cddomain, :usergroup, :accesslevel, :authorized, :acl, :timestamp, :appid ]

  #U=781467570&W=c95e834acfd31ec4655197d262c6b133bd3dcbef&A=userid=781467570&token=c95e834acfd31ec4655197d262c6b133bd3dcbef&company=AMER&segment=AMER&acddomain=A000000011276183&usergroup=ACCT&accesslevel=ACCT&authorized=Y&acl=ADAQDRESGKMAPNQ2QSRFSPTETFTOTTUAURWSQ2NS&timestamp=1246573874&appid=sdc|S=NASDAQ_CHART&C=GET&P=DELL,0,29,1d,1m/n/n

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
    include CacheProc

    attr_accessor :snap_interval
    attr_reader :ioptions, :bars, :interval_type, :frequency, :snaptimes
    attr_reader :response, :body, :login_xml, :cdi, :company, :segment, :account_id, :cookies, :token, :acl, :cddomain
    attr_reader :accesslevel, :appid, :streamer_url, :userid, :usergroup, :w, :a, :u, :authorized, :timestamp, :tcache

    def initialize(options={})
      options.reverse_merge! :login => 'LWSG'
      @ioptions = options
      @bars = []
      @interval_type = nil
      @frequency = nil
      @tcache = { }
      @snaptimes = { }
      @snap_interval = SNAPSHOT_INTERVAL
    end

    def parse_login_xml(h)
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
      @w = @token
      @u = ACCOUNT
      @a = "userid=#{@u}"
      @timestamp = si['timestamp'].first
      @cddomain = si['cd-domain-id'].first
      @accesslevel = si['access-level'].first
      @usergroup = si['usergroup'].first
      @app_id = si['app-id'].first
      @acl = si['acl'].first
      @streamer_url = si['streamer-url'].first
      @authorized = 'Y'
      @appid = 'SDcapture'
    end

    def test
      bars = intraday_for('JAVA', Date.parse('01/03/2009'), Date.parse("01/05/2009"), 30, :debug => true)
#      for bar in bars
#        puts %Q(#{bar.join("\t")})
#      end
      nil
    end

    def attach_to_streamer
      buff = login()
      credentials = XmlSimple.xml_in(buff)
      @login_xml = credentials['xml-log-in'].first
      parse_login_xml(login_xml)
      streamer_xml = streamer_info()
      parse_streamer_info(streamer_xml)
      true
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

    def streamer_uri
      "http://#{streamer_url}/"
    end

    def streamer_info(options={})
      url = URI.parse(TdAmeritrade::STREAMER_INFO)
      form_data = { 'source' => ioptions[:login], 'accountid' => account_id }
      submit_request(TdAmeritrade::STREAMER_INFO, form_data, options)
    end

    def logout(options={})
      url = URI.parse(TdAmeritrade::LOGOUT_URL)
      req = HTTP::Post.new(url.path)
      form_data = { 'source' => ioptions[:login] }
      submit_request(TdAmeritrade::LOGOUT_URL, form_data, options)
    end

    def submit_request(uri, form_data, options={})
      url = URI.parse(uri)
      req = HTTP::Post.new(url.path)
      req.add_field('Cookie', cookies)
      req.set_form_data(form_data)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.set_debug_output($stderr) if options[:debug]

      begin
        res = http.start { http.request(req) }
      rescue Timeout::Error
        retry
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @cookies = res['Set-Cookie']
        return res.body
      else
        res.error!
      end
    end

    def build_param_str()
      STREAMER_ORDER.map do |field|
        val = send(field.to_s.downcase)
        "#{field.to_s}=#{val}"
      end.join('&')
    end

    def submit_request_raw(uri, req, options={})
      url = URI.parse(uri)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if options[:use_ssl]
      http.set_debug_output($stderr) if options[:debug]
      begin
        res = http.start { http.request(req) }
      rescue Timeout::Error
        retry
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return res.body
      else
        res.error!
      end
    end

    def submit_request_stream(uri, req, options={})
      url = URI.parse(uri)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if options[:use_ssl]
      http.set_debug_output($stderr) if options[:debug]
      http.start do
        http.request(req) do |res|
          case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            res.read_body do |segment|
              case segment.length
              when 2: puts segment[0..1]
              when 8: puts "timestamp"
              when 10: puts segment[0..1]+' timestamp'
              else
                puts "quote packet of #{segment.length} starting with #{segment[0..0]}"
              end
            end
          else
            res.error!
          end
        end
      end
    end

    def submit_quote_request(symbol, start_date, end_date, options={})
      form_data = { 'source' => ioptions[:login], 'requestvalue' => symbol, 'requestidentifiertype' => 'SYMBOL',
        'intervaltype' => interval_type, 'intervalduration' => frequency,
        'startdate' => start_date.to_s(:db).delete("-"), 'enddate' => end_date.to_s(:db).delete("-") }
      form_data['extended'] = 'true' if options[:extended]
      response = submit_request(TdAmeritrade::URL, form_data, options)
    end

    def urlencode(str)
      ERB::Util.url_encode(str)
    end

    def group_symbols(symbols)
      ehash = { :nasdaq => [], :nyse => [], nil => [] }
      symbols.each { |s| puts "#{s} #{Ticker.exchange(s)}" }
      symbols.each { |symbol| ehash[Ticker.exchange(symbol)] << symbol }
      ehash.delete(nil)
      ehash.each { |k,v| ehash[k] = urlencode(ehash[k].join('+')) }
      ehash
    end

    def stream(symbols)
      req = build_request(streamer_uri, {})
      req.body = '!' + build_param_str()
      suffix = ''
      bar = urlencode('|')
      shash = { :nyse => 'NYSE_CHART', :nasdaq => 'NASDAQ_CHART' }
      ehash = group_symbols(symbols)
      field_str = urlencode((0..7).to_a.map { |i| i.to_s }.join('+'))
      ehash.each do |k,v|
        suffix << bar+'S='+shash[k]+'&C='+'SUBS'+'&P='+ehash[k]+'&T='+field_str
      end
      req.body << suffix << "\n\n"
      submit_request_stream(streamer_uri, req)
    end

    def snapshot(symbol, options={})
      symbol = symbol.to_s.upcase
      return false if snaptimes[symbol] && snaptimes[symbol] + snap_interval > Time.now
      req = build_request(streamer_uri, {})
      req.body = '!' + build_param_str()
      suffix = ''
      bar = urlencode('|')
      eq = '='
      ehash = { :pcx => 'NYSE_CHART', :nyse => 'NYSE_CHART', :nasdaq => 'NASDAQ_CHART' }
      exch = ehash[Ticker.exchange(symbol)]
      seq = max(Snapshot.last_seq(symbol, Date.today)+1, 90)
      req.body << bar+'S'+eq+exch+'&C'+eq+'GET'+'&P'+eq+symbol+','+seq.to_s+',481,1d,1m'
      req.body << "\n\n"
      snaptimes[symbol] = Time.now
      buff = submit_request_raw(streamer_uri, req, options)
      begin
        symbol, compressed_bars = parse_snapshot(buff)
        buffer = Zlib::Inflate.inflate(compressed_bars)
        Snapshot.populate(process_snapshot(buffer))
      rescue SnapshotProtocolError => e
        #TODO Log something here
      end
    end

    def build_request(uri, form_data)
      url = URI.parse(uri)
      req = HTTP::Post.new(url.path)
      req.set_form_data(form_data)
      req
    end

    def append_form_data(req, params, sep='&')
      req.body << sep << params.map {|k,v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }.join(sep)
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

    def process_snapshot(buffer)
      cleaned = buffer.split(';').delete_if { |s| s.empty? }.map { |e| e.split(',').map { |s| s.gsub(/^0+/,'') } }.compact
      cleaned.pop
      float_proc = proc { |str| str.to_f }
      time_proc = proc { |arg| Time.at(arg*DAY2SEC).utc.to_date }
      cleaned.map do |bar|
        norm = ([] << bar[0].to_sym << bar[1].to_i << bar[2..5].map { |str| cache_proc(str, float_proc) } << bar[6..7].map(&:to_i) << cache_proc(bar.last.to_i, time_proc )).flatten
      end
    end

    def retrieve_quotes_from_file()
      barbuff = IO.read(File.join(RAILS_ROOT, 'tmp', 'barbuf.bin'))
      process_snapshot(barbuff)
    end
  end
end



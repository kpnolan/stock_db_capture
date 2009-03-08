require 'rubygems'
require 'yahoofinance'
require 'ruby-debug'
require 'memcache'
require 'faster_csv'
require 'yaml'
require 'retired_symbol_exception'

# TODO use extend protocol


class String

  def to_time
    self == 'N/A' ? nil : DateTime.parse(self)
  end

  def to_date
    self == 'N/A' ? nil : Date.parse(self)
  end

  def to_i_with_check_for_na
    self == 'N/A' ? nil :  to_i_without_check_for_na
  end

  def to_f_with_check_for_na
    self == 'N/A' ? nil :  to_f_without_check_for_na
  end

   alias_method :to_i_without_check_for_na, :to_i unless method_defined?(:to_i_without_check_for_na)
   alias_method :to_i, :to_i_with_check_for_na

   alias_method :to_f_without_check_for_na, :to_f unless method_defined?(:to_f_without_check_for_na)
   alias_method :to_f, :to_f_with_check_for_na

end

 # TOTO use extend protocol
module YahooFinance
  class BaseQuote

    NA = 'N/A'

    # it's a hueristic, but it seems reasonable
    def valid?
      #puts "#{self.symbol} #{nil_count} #{field_count}" unless nil_count < field_count / 2
      nil_count < field_count / 2
    end

    def opt_pair ( value )
      value.split('-').last.strip.gsub(/%$/, '')
    end

    def convert ( value )
      case value
        when 'N/A'                      : nil
        when /[0-9]+\.?[0-9]*(M|B)/     : value.last == 'M' ? value.to_f * 10**6 : value.to_f * 10**9
        else                              value.to_f
      end
    end

    def get_pair( value, index )
      val = value.split('-')[index].strip
      val == 'N/A' ? nil : value.to_f
    end
  end
end

class TradingDBLoader

  attr_accessor :query_type, :query_protocol, :row_count, :symbol_count, :rejected_count
  attr_accessor :target_model, :start_date, :end_date, :logger, :retired_symbols, :iteration, :start_time

  def initialize(query_type, opts = {})
    self.query_type = query_type
    self.query_protocol, self.target_model = get_query_params(query_type)

    opts.each_pair do |k, v|
      send("#{k}=", v)
    end

    self.row_count = 0
    self.symbol_count = 0
    self.rejected_count = 0
    self.retired_symbols = []
    self.iteration = 0

    if query_type == 'w' || query_type == 'z'
      raise ArgumentError, 'start and end date must be specified' if start_date.nil? || end_date.nil?
    end
  end

  def get_query_params(query_type)
    case query_type
    when 's' : [ YahooFinance::StandardQuote, LiveQuote ]
    when 'x' : [ YahooFinance::ExtendedQuote, CurrentListing ]
    when 'r' : [ YahooFinance::RealTimeQuote, RealTimeQuote ]
    when 'z' : [ YahooFinance::HistoricalQuote, DailyClose ]
    when 'w','W' : [ YahooFinance::HistoricalQuote, Aggregation ]
    else       raise ArgumentError, "Uknown Query Type: #{query_type}"
    end
  end

  def clear_missed_minutes
    Ticker.connection.execute('UPDATE tickers SET missed_minutes = 0')
  end

  def load_quotes(tickers)
    clear_missed_minutes()
    self.retired_symbols = []
    self.start_time = Time.now
    logger.info("Starting with #{tickers.count} symbols")
    ActiveRecord::Base.silence do
      tickers.in_groups_of(100, false) do |group|
        YahooFinance::get_quotes(query_protocol, group) do |qt|
          if qt.valid?
            self.symbol_count += 1
            create_quote_row(target_model, qt)
          else
            logger.error("Invalid quote reqturned, retiring: #{qt.symbol}") if logger
            self.retired_symbols << qt.symbol
          end
        end
      end
    end
    cleanup_iteration(tickers)
  end

  def update_listings(symbols)
    self.start_time = Time.now
    logger.info("Starting with #{symbols.count} symbols")
    ActiveRecord::Base.silence do
      symbols.in_groups_of(10, false) do |group|
        YahooFinance::get_quotes(query_protocol, group) do |qt|
          if qt.valid?
            self.symbol_count += 1
            update_listing(qt)
          else
            logger.error("Invalid Listing reqturned, retiring: #{qt.symbol}") if logger
            ticker = Ticker.find_by_symbol(qt.symbol)
            if ticker.nil?
              puts "Nil for ticker #{qt.symbol}"
            else
              ticker.update_attribute(:dormant, true)
              self.retired_symbols << qt.symbol
            end
          end
        end
      end
    end
    self.retired_symbols
  end

  def cleanup_iteration(tickers)
    self.iteration += 1
    delta = (Time.now - start_time)
    sleep_seconds = 60.0 - delta
    logger.info("Iteration #{@iteration} took #{delta} seconds for #{tickers.length} tickers(#{symbol_count}), #{row_count} rows, #{rejected_count} rejects; #{retired_symbols.length} retireies; sleeping #{sleep_seconds}")
    sleep(sleep_seconds) if sleep_seconds > 0.0
    self.row_count = 0
    self.rejected_count = 0
    self.symbol_count = 0
    self.retired_symbols
  end

  def update_listing(qt)
    syms = CurrentListing.content_columns.collect { |col| col.name.to_sym }
    attrs = syms.inject({}) { |hash, sym| hash[sym] = qt.send(sym); hash }
    begin
      ticker = Ticker.find_by_symbol(qt.symbol)
      if (cl = ticker.current_listing).nil?
        cl = CurrentListing.new(:ticker_id => ticker.id)
      end
    rescue
      base = qt.symbol.delete('-')
      if ticker = Ticker.find_by_symbol(base)
        ticker.update_attribute(:alias, qt.symbol) and retry
      end
      puts "Uknown symbol in update #{qt.symbol}"
    end
    begin
      cl.update_attributes!(attrs)
    rescue => e
      logger.error("Error creating #{qt.symbol} with attrs #{attrs} msg: #{e.message}") if logger
    end
  end

  def create_quote_row(model, qt)
    last_raised_symbol = nil
    attributes = TradingDBLoader.get_attributes(query_type)

    ticker = Ticker.find_by_symbol(qt.symbol)
    return if ticker.nil? || qt[:last_trade_time].nil?

    if qt[:last_trade_time].to_s(:db) =~ /^.+[ ](\d\d):(\d\d):(\d\d)/
      hour, minute, second = $1, $2, $3
      date = qt[:last_trade_date]
      dtstr  = "#{date.to_s(:db)} #{hour}:#{minute}:#{second}"
      dt = DateTime.parse(dtstr)
      qt[:last_trade_time] = dt
    end

    if dt > ticker.last_trade_time
      ticker.update_attribute(:last_trade_time, dt)
      model.create!(:ticker_id => ticker.id, :last_trade => qt.last_trade, :last_trade_time => qt.last_trade_time, :volume => qt.volume)
      # if this is a duplicate record because the exchange has
      # shut down (normal hours) then we pass it up to stop
      # the capture process, otherwise we sampled this symbol
      # withing the last minute of the prior sample. So, we'll just
      # throw out the sample and press on
      self.row_count += 1
    else
      # Here we keep track of the number of times we polled for a ticker and the last_trade_time hasn't increased
      # once we hit a hundred we still haven't seen a trade we stop polling for that symbol
      ticker.increment!(:missed_minutes)
      if ticker.missed_minutes > 100
        logger.info("rejecting #{qt.symbol} last_quote at: #{dt} last recorded enty #{ticker.last_trade_time}")
        self.retired_symbols << qt.symbol if dt.to_date < Date.today
        self.rejected_count += 1
      end
      time = dt.to_time
      t = Time.now
      if t.hour >= 13 && time.hour >= 16 && time.min >= 5
        logger.info("Shutting Down Live Capture at #{Time.now}") if logger
        logger.close if logger
        throw :done
      end
    end
  end

  def self.load_memberships
    sp500 = ListingCategory.find_by_name('Sp500')
    FasterCSV.foreach("#{RAILS_ROOT}/db/data/sp500.csv") do |row|
      symbol, name, segment = row
      t = Ticker.find_by_symbol(symbol)
      lc = ListingCategory.find_by_name(segment)
      if t
        Membership.create(:ticker_id => t.id, :listing_category_id => sp500.id)
        if lc
          Membership.create(:ticker_id => t.id, :listing_category_id => lc.id)
        end
      end
    end
  end

  def self.load_listing_categories
    FasterCSV.foreach("#{RAILS_ROOT}/db/data/listing_categories.csv") do |row|
      name = row.first
      ListingCategory.create(:name => name)
    end
  end

  def self.get_attributes(type)
    hash = case type
           when 's' : YahooFinance::STDHASH
           when 'x' : YahooFinance::EXTENDEDHASH
           when 'r' : YahooFinance::REALTIMEHASH
           end
    hash.values.collect do |v|
      case v.first
      when 'symbol'             : nil
      when 'stock_exchange'     : nil
      when /_range/             : [ "#{v.first}_low", "#{v.first}_high" ]
      else                        v.first
      end
    end.compact.flatten
  end

  def self.create_table_from_fields(table, tname, type)
    hash = case type
           when 's' : YahooFinance::STDHASH
           when 'x' : YahooFinance::EXTENDEDHASH
           when 'r' : YahooFinance::REALTIMEHASH
           end
    hash.each_value do |v|
      type, opts = map_column_type(v[0], v[1])
      columns = get_columns(v[0])
      columns.each do |name|
        table.send(type, name, opts)
      end
    end
  end

  def self.get_columns(name)
    case name
    when 'symbol'           : [ 'ticker_id' ]
    when 'stock_exchange'   : [ ]
    when /_range/           : [ "#{name}_low", "#{name}_high" ]
    else                      [ name ]
    end
  end

  def self.map_column_type(name, method)
    case
    when name == 'symbol'               : [ :integer, { } ]
    when name == 'market_cap'           : [ :float, { } ]
    when name == 'ebitda'               : [ :float, { } ]
    when name =~ /trend/                : [ :string, { :limit => 7 } ]
    when name =~ /range/                : [ :float, { } ]
    when method =~ /to_f/               : [ :float, { } ]
    when method =~ /to_i/               : [ :integer, { } ]
    when method =~ /to_bd/              : [ :decimal, { :precision => 10,  :scale => 2 } ]
    when method =~ /to_date/            : [ :date, { } ]
    when method =~ /to_time/            : [ :datetime, { } ]
    when method =~ /opt_pair/           : [ :float, { } ]
    when method =~ /^val$/              : [ :string, { } ]
    else raise "Uknown column type #{method}"
    end
  end
end

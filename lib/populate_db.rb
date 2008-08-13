require 'rubygems'
require 'yahoofinance'
require 'pp'
require 'ruby-debug'
require 'yaml'

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
      value.split('-').last.strip
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

def critical_section(&block)
  Tempfile.new("LOCK") do |f|
    f.flock(File::LOCK_EX)
    yield
  end
end

class TradingDBLoader

  DB_HASH = {
    :adapter => 'mysql',
    :database => 'active_trader_development',
    :encoding => 'utf8',
    :username => 'root',
    :password => '',
    :host => 'localhost'
  }

  attr_accessor :child_count, :source , :ticker_array, :query_type, :query_protocol
  attr_accessor :aggregate, :target_model, :start_date, :end_date, :child_index

  def initialize(query_type, opts = {})
    opts.reverse_merge! :source => :database
    opts.reverse_merge! :child_count => ENV['CHILD_COUNT'].to_i unless ENV['CHILD_COUNT'].nil?
    opts.reverse_merge! :child_count => 0

    self.query_type = query_type
    self.query_protocol, self.target_model = get_query_params(query_type)

    opts.each_pair do |k, v|
      send("#{k}=", v)
    end

    if query_type == 'w' || query_type == 'z'
      raise ArgumentError, 'start and end date must be specified' if start_date.nil? || end_date.nil?
    end

    if opts[:source] == :database
      self.ticker_array = Ticker.symbols
    else
      File.open("#{RAILS_ROOT}/#{source}", 'r') do |f|
        self.ticker_array = f.readlines.collect! { |s| s.chomp }
      end
    end
  end

  def load()
    start = 0
    target_model.benchmark("Loading #{target_model}s with #{child_count} processes") do
    puts "starting #{child_count} processes"
      target_model.silence do
        child_count.times do |idx|
          self.child_index = idx
          chuck_size = ticker_array.length / child_count
          pid = Process.fork do
            puts "Child #{idx} starting..."
            dispatch_to_loader(ticker_array[start, chuck_size])
            puts "Child #{idx} finished..."
          end
          start += chuck_size
        end
        self.child_index = -1
        dispatch_to_loader(ticker_array[start, ticker_array.length - start])
        Process.waitall
      end
    end
  end

  def load_with_threads()
    start = 0
    target_model.benchmark("Loading #{target_model}s with #{child_count} processes") do
    puts "starting #{child_count} processes"
      target_model.silence do
        child_count.times do |idx|
          self.child_index = idx
          chuck_size = ticker_array.length / child_count
          pid = Process.fork do
            puts "Child #{idx} starting..."
            dispatch_to_loader(ticker_array[start, chuck_size])
            puts "Child #{idx} finished..."
          end
          start += chuck_size
        end
        self.child_index = -1
        dispatch_to_loader(ticker_array[start, ticker_array.length - start])
        Process.waitall
      end
    end
  end

  def get_query_params(query_type)
    case query_type
    when 's' : [ YahooFinance::StandardQuote, DailyReturn ]
    when 'x' : [ YahooFinance::ExtendedQuote, Listing ]
    when 'r' : [ YahooFinance::RealTimeQuote, RealTimeQuote ]
    when 'z' : [ YahooFinance::HistoricalQuote, DailyClose ]
    when 'w','W' : [ YahooFinance::HistoricalQuote, Aggregation ]
    else       raise ArgumentError, "Uknown Query Type: #{query_type}"
    end
  end

  def establish_connection
    env == ENV['RAILS_ENV'].nil? ? 'development' : ENV['RAILS_ENV']
    hash = YAML.load_file("#{RAILS_ROOT}/config/database.yml")[env]
    ActiveRecord::Base.establish_connection(hash)
  end

  def dispatch_to_loader(tickers)
    if %w{ s x r }.include?(query_type)
      load_quotes(tickers)
    elsif query_type == 'z' || query_type == 'w'
      load_historical_quotes(tickers)
    elsif query_type == 'W'
      update_historical_quotes(tickers)
    else
      raise "Unknown query type: #{query_type}"
    end
  end

  def load_quotes(tickers)
    ActiveRecord::Base.silence do
      tickers.each do |ticker|
        YahooFinance::get_quotes(query_protocol, ticker.chomp) do |qt|
          if qt.valid?
            create_quote_row(target_model, qt)
          else
            puts "Unnown symbol: #{ticker}"
          end
        end
      end
    end
  end

#   def load_historical_quotes(tickers)
#     ActiveRecord::Base.silence do
#       tickers.each do |ticker|
#         YahooFinance::get_historical_quotes(ticker, start_date, end_date, query_type).each do |row|
#           create_history_row(ticker, row)
#         end
#       end
#     end
#   end

  def load_historical_quotes(tickers)
    ActiveRecord::Base.silence do
      tickers.each do |ticker|
        t = Ticker.find_by_symbol(ticker)
        puts "unknown ticker: #{ticker}" if t.nil?
        unless t.nil?
          print "[#{child_index}] fetching #{ticker}..."
          rows = YahooFinance::get_historical_quotes(ticker, start_date, end_date, query_type.downcase)
          puts "[#{child_index}] got #{rows.length} rows for #{t.symbol}"
          rows.each do |row|
            create_history_row(ticker, row)
          end
        end
      end
    end
  end

  def find_or_create_exchange(symbol)
    e = Exchange.first(:conditions => {:symbol => symbol})
    e ||= Exchange.create(:symbol => symbol, :country => 'USA', :currency => 'USD')
  end

  def find_or_create_ticker(ename, tname)
    e = find_or_create_exchange(ename)
    t = Ticker.first(:conditions => { :symbol => tname })
    t ||= Ticker.create(:exchange_id => e.id, :symbol => tname)
  end

  def create_quote_row(model, qt)
    attributes = TradingDBLoader.get_attributes(query_type)
    begin
      if source == :database
        ticker = Ticker.first(:conditions => { :symbol => qt.symbol })
      else
        ticker = find_or_create_ticker(qt.stock_exchange, qt.symbol)
      end
      model.new do |ar|
        ar.ticker_id = ticker.id
        attributes.each { |attr| ar[attr] = qt[attr] }
      end.save!
    rescue ActiveRecord::StatementInvalid => e
      if e.to_s =~ /away/
        establish_connection and retry
      else
        puts " ActiveRecord::Base exception #{e.message}"
        retry
      end
    end
  end

  #http://ichart.yahoo.com/table.csv?s=IBM&a=11&b=31&c=2007&d=06&e=30&f=2008&g=w&ignore=.csv
  #http://ichart.yahoo.com/table.csv?s=IBM&a=00&b=1&c=2008&d=06&e=30&f=2008&g=w&ignore=.csv
  def create_history_row(symbol, row)
    attrs = [ :date, :open, :high, :low, :close, :volume, :adj_close]
    model = query_type == 'z' ? DailyClose : Aggregation
    begin
      ticker = Ticker.first(:conditions => { :symbol => symbol })
      model.new do |ar|
        attrs.each {  |attr| ar[attr] = row.shift }
        ar.ticker_id = ticker.id
        ar.month = ar.date.month
        ar.week = ar.date.cweek
        ar.sample_count = 7 if model == Aggregation
      end.save!
    rescue ActiveRecord::StatementInvalid => e
      if e.to_s =~ /away/
        establish_connection and retry
      else
        puts " ActiveRecord::Base exception #{e.message}"
        retry
      end
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

require 'rubygems'
require 'yahoofinance'
require 'pp'
require 'ruby-debug'

class String

  NA = 'N/A'

  def to_time
    self == NA ? nil : DateTime.parse(self)
  end

  def to_date
    self == NA ? nil : Date.parse(self)
  end

  def to_f
    self == NA ? nil : BigDecimal.new(self)
  end

   def to_i_with_check_for_na
     self == NA ? nil :  to_i_without_check_for_na
   end

  alias_method_chain :to_i, :check_for_na unless method_defined?(:to_i_without_check_for_na)

end

module YahooFinance
  class BaseQuote

    NA = 'N/A'

    def opt_pair ( value )
      percent(value.split(value, '-').last.strip)
    end

    def convert ( value )
      case value
        when NA                         : nil
        when /[0-9]+\.?[0-9]*(M|B)/     : value.last == 'M' ? value.to_f * 10**6 : value.to_f * 10**9
        else                              value.to_f
      end
    end

    def get_pair( value, index )
      val = value.split('-')[index].strip
      val == NA ? nil : value.to_f
    end
  end
end

def critical_section(&block)
  File.open('LOCK', File::RDWR|File::CREAT) do |f|
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

  attr_accessor :exchange, :ticker, :listing, :live_statistics, :realtime_statistics, :history
  attr_accessor :child_count, :ticker_file, :ticker_array

  def initialize(opts = {})
    opts.reverse_merge! :ticker_file => "config/tickers.csv"
    opts.reverse_merge! :child_count => ENV['CHILD_COUNT'].to_i unless ENV['CHILD_COUNT'].nil?
    opts.reverse_merge! :child_count => 1, :ticker_file => "config/tickers.csv"

    opts.each_pair do |k, v|
      send("#{k}=", v)
    end

    File.open("#{RAILS_ROOT}/#{ticker_file}", 'r') do |f|
      self.ticker_array = f.readlines
    end
    self.ticker_array = ticker_array
  end

  def load(table_type)
    start = 0
    child_count.times do |idx|
      chuck_size = ticker_array.length / child_count
      pid = Process.fork do
        critical_section {  puts "Child #{idx} starting..." }
        dispatch_to_loader(table_type, ticker_array[start, chuck_size])
        critical_section { puts "Child #{idx} finished..." }
      end
      start += chuck_size
    end
    dispatch_to_loader(table_type, ticker_array[start, ticker_array.length - start])
    Process.waitall
  end

  def dispatch_to_loader(table_type, tickers)
    case table_type
    when 's' : add_live_statistics(tickers)
    when 'x' : add_listings(tickers)
    when 'r' : add_realtime_statistics(tickers)
    when 's' : add_history(tickers)
    end
  end

  def add_listings(tickers)
    xchg = nil
    tickers.each do |ticker|
      YahooFinance::get_quotes( YahooFinance::ExtendedQuote, ticker.chomp ) do |qt|
        if qt.valid?
          critical_section do
            create_listing(qt)
            puts "#{Process.pid}: Created #{ticker}"
          end
        else
          critical_section { puts "                                       Uknown #{ticker}" }
        end
      end
    end
  end

  def find_or_create_exchange(symbol)
    (e = exchange.first(:conditions => {:symbol => symbol})) ? e : exchange.create(:symbol => symbol)
  end

  def find_or_create_ticker(ename, tname)
    e = find_or_create_exchange(ename)
    (t = ticker.first(:conditions => { :symbol => tname })) ? t : ticker.create(:exchange_id => e.id, :symbol => tname)
  end

  def create_listing(qt)
    attributes = TradingDBLoader.get_attributes('x')
    if qt.valid?
      begin
        ticker = find_or_create_ticker(qt.stock_exchange, qt.symbol)
        listing.new do |l|
          l.ticker_id = ticker.id
          attributes.each { |attr| l[attr] = qt[attr] }
        end.save!
      rescue ActiveRecord::StatementInvalid => e
        if e.to_s =~ /away/
          ActiveRecord::Base.establish_connection and retry
        else
          raise e
        end
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

  def self.create_table_from_fields(table, type)
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
    when name == 'market_cap'           : [ :decimal, { :precision => 10,  :scale => 2 } ]
    when name == 'ebitda'               : [ :decimal, { :precision => 10,  :scale => 2 } ]
    when name =~ /trend/                : [ :string, { :limit => 7 } ]
    when name =~ /range/                : [ :decimal, { :precision => 8,  :scale => 2 } ]
    when method =~ /to_f/               : [ :decimal, { :precision => 8,  :scale => 2 } ]
    when method =~ /to_i/               : [ :integer, { } ]
    when method =~ /to_bd/              : [ :decimal, { :precision => 10,  :scale => 2 } ]
    when method =~ /to_date/            : [ :date, { } ]
    when method =~ /to_time/            : [ :datetime, { } ]
    when method =~ /opt_pair/           : [ :float, { } ]
    when method =~ /^val$/              : [ :string, { } ]
    else raise "Uknown column type #{method}"
    end

  end

  private

end

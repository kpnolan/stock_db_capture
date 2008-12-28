require 'rubygems'
require 'yahoofinance'
require 'ruby-debug'
require 'memcache'
require 'faster_csv'
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

  attr_accessor :ticker_array, :query_type, :query_protocol, :memcache
  attr_accessor :target_model, :start_date, :end_date, :logger

  def initialize(query_type, opts = {})

    self.query_type = query_type
    self.query_protocol, self.target_model = get_query_params(query_type)

    opts.each_pair do |k, v|
      send("#{k}=", v)
    end

    if query_type == 'w' || query_type == 'z'
      raise ArgumentError, 'start and end date must be specified' if start_date.nil? || end_date.nil?
    end
  end

  def get_query_params(query_type)
    case query_type
    when 's' : [ YahooFinance::StandardQuote, LiveQuote ]
    when 'x' : [ YahooFinance::ExtendedQuote, Listing ]
    when 'r' : [ YahooFinance::RealTimeQuote, RealTimeQuote ]
    when 'z' : [ YahooFinance::HistoricalQuote, DailyClose ]
    when 'w','W' : [ YahooFinance::HistoricalQuote, Aggregation ]
    else       raise ArgumentError, "Uknown Query Type: #{query_type}"
    end
  end

  def load_quotes(tickers)
    ActiveRecord::Base.silence do
      tickers.in_groups_of(10, false) do |group|
        YahooFinance::get_quotes(query_protocol, group) do |qt|
          if qt.valid?
            create_quote_row(target_model, qt)
            #memcache.increment('#{target_model.to_s}:Counter')
          else
            logger.error("Invalid quote reqturned: #{qt.symbol}") if logger
          end
        end
      end
    end
  end

  def create_quote_row(model, qt)
    attributes = TradingDBLoader.get_attributes(query_type)

    ticker = Ticker.find_by_symbol(qt.symbol)
    return if ticker.nil?
    model.new do |ar|
      ar.ticker_id = ticker.id
      attributes.each { |attr| ar[attr] = qt[attr] }
    end.save!
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

require 'rubygems'
require 'yahoofinance'
require 'pp'
require 'ruby-debug'


module YahooFinance
  class BaseQuote

    NA = 'N/A'

    def opt_pair ( value )
      percent(value.split(value, '-').last.strip)
    end

    def decimal ( value )
      value == NA ? nil : value.to_f
    end

    def dbdate ( value )
      value == NA ? nil : Date.parse(value)
    end

    def dbtime ( value )
      value == NA ? nil : DateTime.parse(value)
    end

    def percent ( value )
      value == NA ? nil : value.chomp('%').to_f
    end

    def range ( value )
      value == NA ? nil : value
    end

    def trend ( value )
      value == NA ? nil : value
    end

    def convert_f ( value )
      value == NA ? nil : value.to_f
    end

    def get_pair( value, index )
      val = value.split('-')[index].strip
      val == NA ? nil : value.to_f
    end
  end
end

def add_listings(eclass, tclass, lclass)
  xchg = nil
  FasterCSV.foreach("#{RAILS_ROOT}/config/tickers.txt") do |row|
    symbol = row.first
    YahooFinance::get_quotes( YahooFinance::ExtendedQuote, symbol ) do |qt|
      if qt.valid?
        create_listing(eclass, tclass, lclass, qt)
        puts "Created #{symbol}"
      else
        puts "                                       Uknown #{symbol}"
      end
    end
  end
end

def find_or_create_exchange(eclass, symbol)
  (e = eclass.find_by_symbol(name)) ? e : eclass.create(:symbol => symbol)
end

def find_or_create_ticker(eclass, tclass, ename, tname)
  exchange = find_or_create_exchange(eclass, ename)
  tclass.create(:exchange_id => exchange.id, :symbol => tname)
end

def create_listing(eclass, tclass, lclass, qt)
  attributes = get_attributes('x')
  if qt.valid?
    ticker = find_or_create_ticker(eclass, tclass, qt.stock_exchange, qt.symbol)
    lclass.new do |listing|
      listing.ticker_id = ticker.id
      attributes.each { |attr| listing[attr] = qt[attr] }
    end.save!
  end
end

def get_attributes(type)
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

def create_table_from_fields(table, type)
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

def get_columns(name)
  case name
    when 'symbol'           : [ 'ticker_id' ]
    when 'stock_exchange'   : [ ]
    when /_range/           : [ "#{name}_low", "#{name}_high" ]
    else                      [ name ]
  end
end

def map_column_type(name, method)
  case
    when name == 'symbol'               : [ :integer, { } ]
    when method =~ /to_f/               : [ :float, { } ]
    when method =~ /to_i/               : [ :integer, { } ]
    when method =~ /to_f/               : [ :float, { } ]
    when method =~ /trend/              : [ :string, { :limit => 7 } ]
    when method =~ /dbdate/             : [ :date, { } ]
    when method =~ /range/              : [ :float, { } ]
    when method =~ /dbtime/             : [ :datetime, { } ]
    when method =~ /percent/            : [ :float, { } ]
    when method =~ /convert_f/          : [ :float, { } ]
    when method =~ /opt_pair/           : [ :float, { } ]
    when method =~ /decimal/            : [ :decimal, { :precision => 10,  :scale => 2 } ]
    when method =~ /^val$/              : [ :string, { } ]
    else raise "Uknown column type #{method}"
  end

end


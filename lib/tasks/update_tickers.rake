require 'populate_db'
require 'hpricot'

namespace :active_trader do
  desc "Populate tickers with Russell 3000"
  task :update_r3000 => :environment do
    count = 0
    names = []
    syms =[]
    doc = Hpricot.parse(File.read("#{RAILS_ROOT}/tmp/russell300.html"))
    (doc/"table/tr/td").each do |elem|
      content = elem.inner_html
      next if content == "&nbsp;"
      if count % 2 == 0
        names << content
      else
        syms << content
      end
      count += 1
    end
    pairs = syms.zip(names).sort.uniq
    eid = Exchange.find_by_symbol("Unknown")
    pairs.each do |pair|
      next if pair.first == "<b>Ticker</b>"
      next if Ticker.find_by_symbol(pair.first)
      p "Adding #{pair.first}: #{pair.last}"
      t = Ticker.create!(:symbol => pair.first, :exchange_id => eid, :active => true)
      e = CurrentListing.create!(:ticker_id => t.id, :name => pair.last)
    end
  end
  desc "Populate ticker DB from listings in CBI's files"
  task :update_symbols => :environment do
    file = ENV['FILE']
    if file =~ /NASDAQ/
      eid = Exchange.find_by_symbol('NasdaqNM').id
    elsif file =~ /nyse/
      eid = Exchange.find_by_symbol('NYSE').id
    elsif file =~ /AMEX/
      eid = Exchange.find_by_symbol('AMEX').id
    else
      raise ArgumentError.new("Uknown exchange")
    end
    IO.foreach(file) do |line|
      unless line.length < 72
        symbol = line[63..71].strip
        unless Ticker.find_by_symbol(symbol)
          Ticker.create!(:symbol => symbol, :exchange_id => eid, :dormant => false, :active => true)
        end
      end
    end
  end
end

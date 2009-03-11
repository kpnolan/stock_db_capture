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
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_tickers.log'))
    file = ENV['FILE']
    if file =~ /nasdaq/
      eid = Exchange.find_by_symbol('NasdaqNM').id
    elsif file =~ /nyse/
      eid = Exchange.find_by_symbol('NYSE').id
    elsif file =~ /etf/
      eid = Exchange.find_by_symbol('ETF').id
    elsif file =~ /index/
      eid = Exchange.find_by_symbol('IDX').id
    else
      raise ArgumentError.new("Uknown exchange")
    end
    IO.foreach(file) do |line|
      symbol = line.strip
      begin
        Ticker.create!(:symbol => symbol, :exchange_id => eid, :dormant => false, :active => true, :validated => true)
      rescue => e
        @logger.info("Duplicate symbol: #{symbol}")
      end
    end
  end

  desc "Make symbol files of 1000 symbols each for use with Askons downloader"
  task :split_symbols => :environment do
    symbols = Ticker.all(:order => 'symbol').map { |t| t.symbol }
    count = 1
    symbols.in_groups_of(300, false) do |list|
      f = File.open("/work/railsapps/stock_db_capture/tmp/symbol#{count}.tlf", "w")
      list.each { |el| f.puts("#{el}\r") }
      count += 1
      f.close
    end
  end
end

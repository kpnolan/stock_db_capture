require 'rubygems'
require 'hpricot'
require 'retired_symbol_exception'

namespace :active_trader do

  desc "Setup the environment for live quote capture"
  task :setup => :environment do
    @symbols = Ticker.active_symbols
    @sleep_seconds = 0
    @iteration = 0
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'capture_live_quotes.log'))
    @ldr = TradingDBLoader.new('s', :logger => @logger)
    @start_time = Time.now
  end

  desc "Start the process which retrieves live quotes from yahoo"
  task :capture_live_quotes => :setup do
    @logger.info("Beginning capture of live quotes at #{Time.now}")
    catch (:done) do
      while true
        @logger.info("Given #{@symbols.length} symbols")
        stale_symbols = @ldr.load_quotes(@symbols)

        reset()

        stale_symbols.each do |sym|
          @logger.info("Removing #{sym} from Array")
          @symbols.delete(sym)
        end
      end
    end
    @logger.info("Shutting Down Live Capture at #{Time.now}")
    @logger.close
  end

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

  def reset()
    @iteration += 1
    delta = (Time.now - @start_time)
    @sleep_seconds = 60.0 - delta
    @logger.info("Iteration #{@iteration} took #{delta} seconds for #{@ldr.symbol_count} symbols, #{@ldr.row_count} rows, #{@ldr.rejected_count} rejects; sleeping #{@sleep_seconds}")
    sleep(@sleep_seconds) if @sleep_seconds > 0.0
    @start_time = Time.now
    @ldr.row_count = 0
    @ldr.symbol_count = 0
    @ldr.rejected_count = 0
  end
end

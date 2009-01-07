require 'rubygems'
#require 'hpricot'
require 'retired_symbol_exception'

namespace :active_trader do

  desc "Setup the environment for live quote capture"
  task :setup => :environment do
    @symbols = Ticker.active_symbols
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'capture_live_quotes.log'))
    @ldr = TradingDBLoader.new('s', :logger => @logger)
    @logger.info("Startup live capture at #{Time.now}")
  end

  desc "Start the process which retrieves live quotes from yahoo"
  task :capture_live_quotes => :setup do
    @logger.info("Beginning capture of live quotes at #{Time.now}")
    catch (:done) do
      symbols = @symbols
      while true
        stale_symbols = @ldr.load_quotes(symbols)
        symbols -= stale_symbols
      end
    end
  end
end

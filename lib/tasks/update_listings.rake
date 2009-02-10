require 'rubygems'
require 'retired_symbol_exception'
require 'benchmark'

namespace :active_trader do

  desc "Setup the environment for live quote capture"
  task :setup_listings => :environment do
    @symbols = Ticker.active_symbols
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_listings.log'))
    @ldr = TradingDBLoader.new('x', :logger => @logger)
    @logger.info("Startup update listings at #{Time.now}")
  end

  desc "Start the process which retrieves live quotes from yahoo"
  task :update_listings => :setup_listings do
    bm = Benchmark.measure("Time retrieving @symbol.length Listings from Yahoo") do
      @ldr.update_listings(@symbols)
    end
    puts bm
  end
end

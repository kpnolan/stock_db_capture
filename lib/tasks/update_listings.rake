require 'rubygems'
require 'retired_symbol_exception'
require 'benchmark'

namespace :active_trader do

  desc "Setup the environment for listing queries"
  task :setup_listings => :environment do
    @symbols = Ticker.active_symbols
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_listings.log'))
    @ldr = TradingDBLoader.new('x', :logger => @logger)
    @logger.info("Startup update listings at #{Time.now}")
  end

  desc "Update listing info for ticker set"
  task :update_listings => :setup_listings do
    bm = Benchmark.measure("Time retrieving @symbol.length Listings from Yahoo") do
      @ldr.update_listings(@symbols)
    end
    puts bm
  end

  desc "Validate Symbols"
  task :validate_symbols => :environment do
    @symbols = Ticker.all.map { |t| t.symbol }
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'validate_symbols.log'))
    @ldr = TradingDBLoader.new('n', :logger => @logger)
    @ldr.validate_symbols(@symbols)
  end

  desc "Cleanup any symbols that not in cannocial form"
  task :cleanup_symbols => :setup_listings do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'cleanup_symbols.log'))
    @ldr = TradingDBLoader.new('n', :logger => @logger)
    @ldr.cleanup_symbols()
  end
end

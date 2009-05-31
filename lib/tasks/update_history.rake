require 'rubygems'
require 'log_returns'
require 'load_bars'

extend LoadBars
extend LogReturns

namespace :active_trader do

  desc "Load Daily Bars table with entire history"
  task :load_intraday => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_intraday.log'))
    load_intraday_history(@logger)
  end

  desc "Update DailyBar table with new history"
  task :update_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    update_daily_history(@logger)
  end

  desc "Load all Daily Close with momentum values"
  task :load_returns => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_returns.log'))
    initialize_returns(@logger)
  end

  desc "Update Daily Close with new momentum values"
  task :load_returns => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_returns.log'))
    update_returns(@logger)
  end

  desc "Load TDA Stocks"
  task :load_tda_stocks => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'tda_symbol_load.log'))
    load_tda_symbols(@logger)
  end

  desc "Clear locks on Tickers"
  task :clear_locks => :environment do
    Ticker.connection.execute('update tickers set locked = 0')
  end
end

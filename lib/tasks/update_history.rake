require 'rubygems'
require 'populate_db'
require 'load_daily_close'
require 'log_returns'

extend LoadDailyClose
extend LogReturns

namespace :active_trader do

  desc "Load Daily Close table with entire history"
  task :load_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    load_history(@logger)
  end

  desc "Update Daily Close table with new history"
  task :update_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    update_history(@logger)
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

  desc "Load TDA History"
  task :load_tda => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'tda_load.log'))
    load_tda_history(@logger)
  end

  desc "Clear locks on Tickers"
  task :clear_locks => :environment do
    Ticker.connection.execute('update tickers set locked = 0')
  end
end

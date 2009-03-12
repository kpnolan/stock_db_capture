require 'rubygems'
require 'populate_db'
require 'load_daily_close'
require 'log_returns'

extend LoadDailyClose
extend LogReturns

namespace :active_trader do

  desc "Update Daily Close table with new history"
  task :update_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    update_history(@logger)
  end

  desc "Backfill history to 01/01/2000"
  task :backfill_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    backfill_history(@logger)
  end

  desc "Update Daily Close with momentum values"
  task :update_returns => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_returns.log'))
    initialize_returns(@logger)
#    update_returns(@logger)
  end

  desc "Clear locks on Tickers"
  task :clear_locks => :environment do
    Ticker.connection.execute('update tickers set locked = 0')
  end
end

require 'rubygems'
require 'populate_db'
require 'load_daily_close'
require 'log_returns'

extend LoadDailyClose
extend LogReturns

namespace :active_trader do

  desc "Initialize returns, log returns and anualized returns"
  task :init_returns => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    initialize_returns(@logger)
  end

  desc "Update Daily Close table with new history"
  task :update_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    update_history(@logger)
  end

  desc "Update Daily Close table with new history"
  task :update_returns => :update_history do
    update_returns(@logger)
  end
end

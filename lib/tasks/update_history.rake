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
    update_returns(@logger)
  end
end

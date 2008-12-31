require 'rubygems'
require 'populate_db'
require 'load_daily_close'

extend LoadDailyClose

namespace :active_trader do

  desc "Setup the environment for live quote capture"
  task :setup => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
  end

  desc "Update Daily Close table with new history"
  task :update_history => :setup do
    update_history()
  end
end

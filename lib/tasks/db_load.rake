require 'load_daily_close'

include LoadDailyClose

namespace :db do
  namespace :load do
    desc "Load daily closes from yahoo"
    task :daily_closes => :environment do
      $logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'deepend_daily_closes.log'))
      load_more_history($logger)
    end
  end
end

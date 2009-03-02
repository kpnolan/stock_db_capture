require 'load_intraday_bars'

extend LoadIntradayBars

namespace :active_trader do
  desc "Aggregate Live Quotes to 15 minute bars for all Live Quotes that do not yet have bars"
  task :load_intraday => :environment do
    $logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'load_intraday.log'))
    initialize(ENV['FILE'], $logger)
    load_table()
  end
end



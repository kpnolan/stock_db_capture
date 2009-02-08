require 'aggregator'
include Aggregator

namespace :active_trader do
  desc "Aggregate Live Quotes to 15 minute bars for all Live Quotes that do not yet have bars"
  task :update_aggregates => :environment do
    $logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_aggregates.log'))
    compute_aggregates(15.minutes)
  end
  desc "Aggregate Live Quotes to 15 minute bars for today"
  task :update_daily_aggregates => :environment do
    $logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_aggregates.log'))
    Ticker.active_symbols.each do |symbol|
      LiveQuote.compute_aggregate(symbol, Date.today, 15.minutes)
    end
  end
end


namespace :active_trader do
  desc "Aggregate Live Quotes to 15 minute bars for all Live Quotes that do not yet have bars"
  task :update_aggregates => :environment do
    $logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_aggregates.log'))
    dates = LiveQuote.out_of_date
    Ticker.active_symbols.each do |symbol|
      dates.each do |date|
        LiveQuote.compute_aggregate(symbol, date, 15.minutes)
      end
    end
  end
  desc "Aggregate Live Quotes to 15 minute bars for today"
  task :update_daily_aggregates => :environment do
    $logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_aggregates.log'))
    Ticker.active_symbols.each do |symbol|
      LiveQuote.compute_aggregate(symbol, Date.today, 15.minutes)
    end
  end
end


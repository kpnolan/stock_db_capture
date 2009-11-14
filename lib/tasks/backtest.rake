require 'backtester'

namespace :active_trader do
  desc "Run the backtester"
  task :backtest => :environment do
    proc_id = ENV['PROC_ID'] ? ENV['PROC_ID'].to_i : 0
    require File.join(RAILS_ROOT, 'btest', "#{ENV['CONFIG']}.rb")
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', "#{ENV['CONFIG']}_backtest_#{proc_id}.log"))
    $backtester.run(logger)
  end
end

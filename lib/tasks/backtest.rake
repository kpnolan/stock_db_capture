namespace :active_trader do
  desc "Run the backtester front-end"
  task :producer => :environment do
    require 'backtest/producer/base'
    proc_id = ENV['PROC_ID'] ? ENV['PROC_ID'].to_i : 0
    cfg_path = File.join(RAILS_ROOT, 'btest', "#{ENV['CONFIG']}.cfg")
    Backtest::Producer::Base.new(cfg_path)
  end

  desc "Run the backtester back-end"
  task :consumer do
    require 'backtest/consumer/base'
    cfg_path = File.join('/work', 'tdameritrade', 'stock_db_capture', 'btest', "#{ENV['CONFIG']}.cfg")
    puts cfg_path
    consumer = Backtest::Consumer::Base.new(cfg_path)
    consumer.run()
  end
end

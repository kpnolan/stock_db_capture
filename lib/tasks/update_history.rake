# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'log_returns'
require 'load_bars'

extend LoadBars
extend LogReturns

namespace :active_trader do

  desc "Update Intra Day Bars"
  task :update_intraday => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_intraday.log'))
    update_intraday_history(logger)
  end

  desc "Update DailyBars"
  task :update_tda => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    update_daily_history(logger)
  end

  desc "Load a decade's worth of daily bars"
  task :load_dailys => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'load_dailys.log'))
    load_all_dailys(logger)
  end

  #  desc "Load TDA Stocks"
  #  task :load_tda_stocks => :environment do
  #    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'tda_symbol_load.log'))
  #    load_tda_symbols()
  #  end

  desc "Backfill missing bars"
  task :backfill => :environment do
    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'backfill.log'))
    backfill_missing_bars()
  end

  desc "Fill Missing Bars"
  task :fill_missing_bars => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'backfill.log'))
    fill_missing_bars(logger)
  end

  desc "Report missing bars"
  task :report_missing_bars => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'missing_bars.log'))
    report_missing_bars(logger)
  end

  desc "Clear locks on Tickers"
  task :clear_locks => :environment do
    Ticker.connection.execute('update tickers set locked = 0')
  end

  desc "Update Yahoo"
  task :update_yahoo => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'yahoo_bars.log'))
    update_yahoo_history(logger)
  end

  desc "Update Google Dailys"
  task :update_google => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'google_bars.log'))
    load_google_history(logger)
  end

  desc "Update Splits"
  task :load_splits => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'splits.log'))
    load_splits(logger)
  end
end

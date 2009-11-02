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
    update_intraday(logger)
  end

  desc "Load TDA"
  task :load_TDA => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'load_TDA.log'))
    load_TDA(logger)
  end

  desc "Update TDA"
  task :update_tda => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_TDA.log'))
    update_TDA(logger)
  end

  desc "Mark Delisted TDA"
  task :mark_delisted => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'detect_delisting.log'))
    detect_delisted(logger)
  end

  #  desc "Load TDA Stocks"
  #  task :load_tda_stocks => :environment do
  #    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'tda_symbol_load.log'))
  #    load_tda_symbols()
  #  end

  desc "Load Yahoo"
  task :load_yahoo => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'load_yahoo.log'))
    load_yahoo(logger)
  end

  desc "Update Yahoo"
  task :update_yahoo => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_yahoo.log'))
    update_yahoo(logger)
  end

  desc "Load Google"
  task :load_google => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'load_google.log'))
    load_google(logger)
  end

  desc "Update Google Dailys"
  task :update_google => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_google.log'))
    update_google(logger)
  end

  desc "Update Splits"
  task :load_splits => :environment do
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'splits.log'))
    load_splits(logger)
  end

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

  desc "Run Simulator"
  task :simulate => :environment do
    Sim::SystemMgr.run()
  end
end

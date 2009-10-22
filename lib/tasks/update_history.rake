# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'log_returns'
require 'load_bars'

extend LoadBars
extend LogReturns

namespace :active_trader do

  desc "Load Intra Day Bars table with entire history"
  task :load_intraday => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_intraday.log'))
    load_intraday_history(@logger)
  end

  desc "Update DailyBar table with new history"
  task :update_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_history.log'))
    update_daily_history(@logger)
  end

  desc "Update IntrDayBar table with new history"
  task :update_intraday_history => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_intraday_history.log'))
    update_intraday_history(@logger)
  end

  desc "Load all Daily Close with logr values"
  task :load_logr => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'init_logr.log'))
    initialize_returns(@logger)
  end

  desc "Update DailyBars with new logr values"
  task :update_logr => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_returns.log'))
    update_returns(@logger)
  end

  desc "Load a year's worth of daily bars"
  task :load_dailys => :environment do
    proc_id = ENV['YAHOO_ID'].to_i
    proc_cnt = ENV['YAHOO_CNT'].to_i
    if proc_cnt.zero?
      raise ArgumentError, "Environment variable YAHOO_ID and YAHOO_CNT must be set"
    end
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'load_dailys.log'))
    load_all_dailys(logger, proc_id, proc_cnt)
  end

  desc "Load TDA Stocks"
  task :load_tda_stocks => :environment do
    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'tda_symbol_load.log'))
    load_tda_symbols()
  end

  desc "Backfill missing bars"
  task :backfill => :environment do
    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'backfill.log'))
    backfill_missing_bars()
  end

  desc "Verify missing bars"
  task :verify_backfill => :environment do
    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'backfill.log'))
    verify_backfill()
  end

   desc "Fill Missing Bars"
   task :fill_missing_bars => :environment do
    proc_id = ENV['PROC_ID'].to_i
    proc_cnt = ENV['PROC_CNT'].to_i
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'backfill.log'))
    fill_missing_bars(logger, proc_id, proc_cnt)
   end

  desc "Report missing bars"
  task :report_missing_bars => :environment do
    proc_id = ENV['PROC_ID'].to_i
    proc_cnt = ENV['PROC_CNT'].to_i
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'missing_bars.log'))
    report_missing_bars(logger, proc_id, proc_cnt)
  end

  desc "Clear locks on Tickers"
  task :clear_locks => :environment do
    Ticker.connection.execute('update tickers set locked = 0')
  end

  desc "Initialize Logr with optional year"
  task :init_logr => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'init_logr.log'))
    initialize_returns(@logger)
  end

  desc "Update Logr with"
  task :update_logr => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_logr.log'))
    update_returns(@logger)
  end

  desc "Load Yahoo Dailys"
  task :load_yahoo => :environment do
    proc_id = ENV['YAHOO_ID'].to_i
    proc_cnt = ENV['YAHOO_CNT'].to_i
    if proc_cnt.zero?
      raise ArgumentError, "Environment variable YAHOO_ID and YAHOO_CNT must be set"
    end
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'yahoo_bars.log'))
    load_yahoo_bars(logger, proc_id, proc_cnt)
  end

  desc "Load Google Dailys"
  task :load_google => :environment do
    proc_id = ENV['GOOG_ID'].to_i
    proc_cnt = ENV['GOOG_CNT'].to_i
    if proc_cnt.zero?
      raise ArgumentError, "Environment variable GOOG_ID and GOOG_CNT must be set"
    end
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'google_bars.log'))
    load_google_bars(logger, proc_id, proc_cnt)
  end

  desc "Update Yahoo Dailys"
  task :update_yahoo => :environment do
    proc_id = ENV['YAHOO_ID'].to_i
    proc_cnt = ENV['YAHOO_CNT'].to_i
    if proc_cnt.zero?
      raise ArgumentError, "Environment variable YAHOO_ID and YAHOO_CNT must be set"
    end
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'update_yahoo_bars.log'))
    update_yahoo_bars(logger, proc_id, proc_cnt)
  end

  desc "Load Splits"
  task :load_splits => :environment do
    proc_id = ENV['YAHOO_ID'].to_i
    proc_cnt = ENV['YAHOO_CNT'].to_i
    if proc_cnt.zero?
      raise ArgumentError, "Environment variable YAHOO_ID and YAHOO_CNT must be set"
    end
    logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'splits.log'))
    load_splits(logger, proc_id, proc_cnt)
  end

  desc "Backfill zero volume days"
  task :bf_zero_volume => :environment do
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'zero_volume.log'))
    backfill_zero_volume_missing_bars(@logger)
  end
end

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'log_returns'
require 'load_bars'
require 'bar_utils'

extend BarUtils
extend LoadBars
extend LogReturns

namespace :active_trader do

  desc "Update Intra Day Bars"
  task :update_intraday => :environment do
    logger = init_logger(:update_intraday)
    update_intraday(logger)
  end

  desc "Forked Update Intra Day Bars"
  task :forked_update_intraday => :environment do
    logger = init_logger(:update_intraday)
    forked_update_intraday(logger)
  end

  desc "Load TDA"
  task :load_tda => :environment do
    logger = init_logger(:load_tda)
    load_TDA(logger)
  end

  desc "Update TDA"
  task :update_tda => :environment do
    logger = init_logger(:update_tda)
    update_TDA(logger)
  end

  desc "Mark Delisted TDA"
  task :mark_delisted => :environment do
    logger = init_logger(:mark_delisted)
    detect_delisted(logger)
  end

  #  desc "Load TDA Stocks"
  #  task :load_tda_stocks => :environment do
  #    #@logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'tda_symbol_load.log'))
  #    load_tda_symbols()
  #  end

  desc "Load Yahoo"
  task :load_yahoo => :environment do
    logger = init_logger(:load_yahoo)
    load_yahoo(logger)
  end

  desc "Update Yahoo"
  task :update_yahoo => :environment do
    logger = init_logger(:update_yahoo)
    update_yahoo(logger)
  end

  desc "Load Google"
  task :load_google => :environment do
    logger = init_logger(:load_google)
    load_google(logger)
  end

  desc "Update Google Dailys"
  task :update_google => :environment do
    logger = init_logger(:update_google)
    update_google(logger)
  end

  desc "Update Splits"
  task :load_splits => :environment do
    logger = init_logger(:load_splits)
    load_splits(logger)
  end

  desc "Fill Missing Bars"
  task :fill_missing_bars => :environment do
    model = ENV['MODEL'].nil? ? GoogleBar : ENV['MODEL']
    start_date = ENV['START'].nil? ? nil : Date.parse( ENV['START'])
    end_date = ENV['END'].nil? ? nil : Date.parse( ENV['END'])
    logger = init_logger(:fill_missing_bars)
    fill_missing_bars(logger, model, start_date, end_date)
  end

  desc "Report missing bars"
  task :report_missing_bars => :environment do
    model = ENV['MODEL'].nil? ? GoogleBar : ENV['MODEL']
    start_date = ENV['START'].nil? ? nil : Date.parse( ENV['START'])
    end_date = ENV['END'].nil? ? nil : Date.parse( ENV['END'])
    logger = init_logger(:missing_bars)
    report_missing_bars(logger, model, start_date, end_date)
  end

  desc "Clear locks on Tickers"
  task :clear_locks => :environment do
    Ticker.connection.execute('update tickers set locked = 0')
  end
end

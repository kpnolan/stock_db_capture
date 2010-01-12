# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
#require 'watch_list'

namespace :active_trader do
  namespace :watch_list do

    desc "Load New Symbols for the Watch List"
    task :populate => :environment do
      log_name = "stock_watch_#{Date.today.to_s(:db)}.log"
      @logger ||= ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', log_name))
      @sw = Trading::StockWatcher.new(@logger)
      @sw.reset()
    end

    desc "Purge the Watch List"
    task :purge => :environment do
      log_name = "purge_watch_#{Date.today.to_s(:db)}.log"
      @logger ||= ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', log_name))
      @sw = Trading::StockWatcher.new(@logger)
      @sw.purge()
    end

    desc "Generate Entry CSV"
    task :csv => :environment do
      @sw = Trading::StockWatcher.new(nil)
      @sw.generate_entry_csv()
    end


    desc "Begin Updating Watch List"
    task :start_watching => :environment do
      log_name = "stock_watch_#{Date.today.to_s(:db)}.log"
      @logger ||= ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', log_name))
      @sw = Trading::StockWatcher.new(@logger)
      @sw.start_watching()
    end
  end
end

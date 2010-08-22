#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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

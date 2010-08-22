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

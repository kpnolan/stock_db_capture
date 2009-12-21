# == Schema Information
# Schema version: 20091220213712
#
# Table name: yahoo_bars
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  opening   :float
#  close     :float
#  high      :float
#  volume    :integer(4)
#  low       :float
#  bartime   :datetime
#  adj_close :float
#  bardate   :date
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'date'

class YahooBar < ActiveRecord::Base

  # this is the order of the data fields returned from TDAmeritrade for a Yahoo request
  COLUMN_ORDER = [ :opening, :high, :low, :close, :volume, :adj_close ]

  belongs_to :ticker

  extend BarUtils
  extend TableExtract

  class << self

    def order ; 'bardate, id'; end
    def time_convert ; 'to_time' ;  end
    def time_class ; Time ;  end
    def time_res; 1.day; end
    def source_id; 'Y'; end

    def update(logger)
      update_bars(logger, YahooFinance::QuoteServer.new(:logger => logger), self.to_s.tableize)
    end

    def load(logger)
      load_bars(logger, YahooFinance::QuoteServer.new(:logger => logger), self.to_s.tableize)
    end

    def create_bar(symbol, ticker_id, bar_ary)
      bar = bar_ary.dup
      datestr = bar.shift
      attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift.to_f; h }
      date = Date.parse(datestr)
      bartime = date.to_time.localtime.change(:hour => 6, :min => 30)
      attrs[:bartime] = bartime
      attrs[:bardate] = bartime.to_date
      attrs[:ticker_id] = ticker_id
      begin
        create! attrs
      rescue Exception => e
        puts "#{attrs[:bartime]}:#{e.to_s}"
      end
    end
  end
end

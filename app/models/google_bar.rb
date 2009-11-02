# == Schema Information
# Schema version: 20091029212126
#
# Table name: google_bars
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  opening   :float
#  close     :float
#  high      :float
#  volume    :integer(4)
#  low       :float
#  bartime   :datetime
#  bardate   :date
#

require 'date'

class GoogleBar < ActiveRecord::Base

  # this is the order of the data fields returned from TDAmeritrade for a Yahoo request
  COLUMN_ORDER = [ :opening, :high, :low, :close, :volume ]

  belongs_to :ticker

  extend TableExtract
  extend BarUtils

  class << self

    def order ; 'bardate, id'; end
    def time_convert ; 'to_time' ;  end
    def time_class ; Time ;  end
    def time_res; 1.day; end
    def source_id; 'G'; end

    def load(logger)
      load_bars(logger, GoogleFinance::QuoteServer.new(:logger => logger), self.to_s.tableize)
    end

    def update(logger)
      update_bars(logger, GoogleFinance::QuoteServer.new(), self.to_s.tableize)
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

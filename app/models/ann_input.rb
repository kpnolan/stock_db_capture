# == Schema Information
# Schema version: 20100123024049
#
# Table name: ann_inputs
#
#  id        :integer(4)      not null, primary key
#  O         :float
#  H         :float
#  L         :float
#  C         :float
#  RSI       :float
#  V         :integer(4)
#  RVIG      :float
#  MACD      :float
#  O0        :float
#  ticker_id :integer(4)
#  bartime   :datetime
#  O1        :float
#  O5        :float
#

class AnnInput < ActiveRecord::Base
  belongs_to :ticker

  class << self
    def populate(symbol, start_date, end_date)
      startd = start_date.to_date
      endd = end_date.to_date
      ts = Timeseries.new(symbol, startd..endd, 1.day)
      macd = ts.macdfix(:result => :macd_hist).to_a
      range = ts.index_range
      rsi = ts.rsi(:result => :array)
      rvig = ts.rvig(:result => :rvigor).to_a
      lengths = { :ts => ts.length, :macd => macd.length, :rsi => rsi.length, :rvig => rvig.length }
      lengths.inject({}) do |mem, pair|
        if mem == {}
          pair.last
        elsif mem != pair.last
          puts "#{pair.first} has len: #{pair.last}"
        else
          mem
        end
      end
      cols = %w{ bartime o h l c v rvig rsi macd }.map(&:to_sym)
      array_set = ts.timevec[range].zip(ts.opening[range].to_a, ts.high[range].to_a, ts.low[range].to_a, ts.close[range].to_a, ts.volume[range].to_a, rvig, rsi, macd)
      array_set.each do |row|
        attrs = cols.zip(row).inject({}) { |m, pair| m[pair.first] = pair.last; m}
        attrs[:v] = attrs[:v].to_i
        attrs[:ticker_id] = ts.ticker_id
        begin
          create!(attrs)
        rescue Exception => e
          debugger
        end
      end
      array_set.length
    end
  end
end


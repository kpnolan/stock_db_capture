# == Schema Information
# Schema version: 20090707232154
#
# Table name: snapshots
#
#  id           :integer(4)      not null, primary key
#  ticker_id    :integer(4)
#  snaptime     :datetime
#  seq          :integer(4)
#  open         :float
#  high         :float
#  low          :float
#  close        :float
#  volume       :integer(4)
#  accum_volume :integer(4)
#  secmid       :integer(4)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Snapshot < ActiveRecord::Base
  belongs_to :ticker

  FORDER = [ :symbol, :seq, :open, :high, :low, :close, :volume, :secmid, :date ]

  class << self

    def form_volume_sql(ticker_id, date)
      sql = "select accum_volume from snapshots where ticker_id = #{ticker_id} and date(snaptime) = '#{date.to_s(:db)}' having max(seq)"
    end

    def form_seq_sql(ticker_id, date)
      sql = "select max(seq) from snapshots where ticker_id = #{ticker_id} and date(snaptime) = '#{date.to_s(:db)}'"
    end

    def last_seq(symbol, date)
      ticker_id = Ticker.lookup(symbol).id
      seq_str = Snapshot.connection.select_value(form_seq_sql(ticker_id, date))
      seq_str.nil? ? -1 : seq_str.to_i
    end

    def accum_vol(ticker_id, date)
      av_str = Snapshot.connection.select_value(form_volume_sql(ticker_id, date))
      av_str.nil? ? 0 : av_str.to_i
    end

    def populate(snapshot)
      return nil if snapshot.empty?
      ticker = Ticker.lookup(snapshot.first.first)
      accum_volume = accum_vol(ticker.id, snapshot.first.last)
      for bar in snapshot
        ss = bar.dup
        attrs = FORDER.inject({}) { |h, k| h[k] = ss.shift; h }
        attrs.delete(:symbol)
        accum_volume += attrs[:volume]
        attrs[:ticker_id] = ticker.id
        attrs[:snaptime] = calc_time(attrs[:seq], attrs[:date])
        attrs[:accum_volume] = accum_volume
        attrs.delete :date
        create!(attrs)
      end
      snapshot.length
    end
    #
    # Calculate the time from the current date and the minute sequence number as ET
    #
    def calc_time(seq, date)
      date.to_time.midnight + 5.hours + seq.minutes
    end
  end
end

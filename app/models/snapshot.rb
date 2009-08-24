# == Schema Information
# Schema version: 20090821150720
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

class Snapshot < ActiveRecord::Base
  belongs_to :ticker

  validates_presence_of :ticker_id

  FORDER = [ :symbol, :seq, :open, :high, :low, :close, :volume, :secmid, :date ]

  extend Predict

  class << self

    def form_volume_sql(ticker_id, date)
      sql = "select accum_volume from snapshots where ticker_id = #{ticker_id} and date(snaptime) = '#{date.to_s(:db)}' having max(seq)"
    end

    def form_seq_sql(ticker_id, date)
      sql = "select max(seq) from snapshots where ticker_id = #{ticker_id} and date(snaptime) = '#{date.to_s(:db)}'"
    end

    def last_close(ticker_id, date=Date.today)
      bar = last_bar(ticker_id, date)
      bar.nil? ? nil : bar[:close]
    end

    def last_bar(ticker_id, date=Date.today, count=false)
      snap_ary = Snapshot.find(:all, :conditions => ['ticker_id = ? and date(snaptime) = ?', ticker_id, date], :order => 'seq desc')
      high = snap_ary.map(&:high).max
      low = snap_ary.map(&:low).min
      open = snap_ary.last.open
      close = snap_ary.first.open
      values = [open, high, low, close, snap_ary.first.accum_volume, snap_ary.first.snaptime]
      bar = [:open, :high, :low, :close, :volume, :time].inject({}) { |h, k| h[k] = values.shift; h }
      count ? [bar, snap_ary.length] : bar
    end

    def last_seq(symbol, date)
      # TODO change symbol to ticker or id
      ticker_id = Ticker.lookup(symbol).id
      seq_str = Snapshot.connection.select_value(form_seq_sql(ticker_id, date))
      seq_str.nil? ? -1 : seq_str.to_i
    end

    def accum_vol(ticker_id, date)
      av_str = Snapshot.connection.select_value(form_volume_sql(ticker_id, date))
      av_str.nil? ? 0 : av_str.to_i
    end

    def predict(ticker_or_sym, bar_val=:close, date=Date.today, predict_to=480)
      raise ArgumentError, "bar_val not on of #{FORDER.join(', ')}" unless FORDER.include? bar_val
      ticker_id = Ticker.resolve_id(ticker_or_sym)
      series = find(:all, :conditions => ["ticker_id = ? and date(snaptime) = ?", ticker_id, date], :order => :seq)
      xvec = series.map(&:seq)
      yvec = series.map(&bar_val)
      yval, sd = linear(xvec, yvec, predict_to)
      return yval, sd, series.length
    end

    def populate(snapshot)
      return 0 if snapshot.empty?
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

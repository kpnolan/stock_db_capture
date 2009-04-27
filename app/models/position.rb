# == Schema Information
# Schema version: 20090425175412
#
# Table name: positions
#
#  id               :integer(4)      not null, primary key
#  ticker_id        :integer(4)
#  entry_date       :datetime
#  exit_date        :datetime
#  entry_price      :float
#  exit_price       :float
#  num_shares       :integer(4)
#  stop_loss        :string(255)
#  strategy_id      :integer(4)
#  days_held        :integer(4)
#  nomalized_return :floaT              # FIXME! spelling
#  risk_factor      :float
#  week             :integer(4)
#  scan_id          :integer(4)
#

class Position < ActiveRecord::Base

  extend TradingCalendar

  has_and_belongs_to_many :scans
  belongs_to :ticker
  belongs_to :strategy

  def self.open(population, strategy, ticker, entry_date, entry_price)
    week = entry_date.to_date.cweek
    create!(:scan_id => population.id, :strategy_id => strategy.id, :ticker_id => ticker.id,
            :entry_price => entry_price, :entry_date => entry_date, :num_shares => 1, :week => week)
  end

  def close_at_max(options={})
    options.reverse_merge! :method => :sql
    hold_time = options[:hold_time] # i.e. 3..10 days
    start_date = entry_date.to_date + hold_time.begin
    end_date = Position.trading_to_calendar(start_date, hold_time.end-hold_time.begin)

#    ts = Timeseries.new(ticker_id, start_date..end_date, 1.day,
#                        :populate => true, :pre_buffer => false)
#    dummy, idx, vecs = ts.rvi(:result => :raw, :noplot => true)
#    raise ArgumentError.new("RVi: returned #{vec.length}, expected 1") unless vecs.length == 1
#    risk = vecs.first.average
    risk = nil
    if options[:method] == :sql
      max_adj_close, exit_date = DailyClose.max_between(:adj_close, ticker_id, start_date..end_date)
      days_held = Position.trading_day_count(entry_date.to_date, exit_date.to_date)
      normalized_return = ((max_adj_close - entry_price) / entry_price) / days_held
    else
      adj_close_vec = ts.adj_close
      max_adj_close = adj_close_vec.max
      days_held = adj_close_vec.index(max_adj_close)
      exit_date = ts.index2time(index).to_date
      logrs = ts.logr[0..index].sum
      normalized_return = Math.exp(logrs)
    end
    update_attributes!(:exit_price => max_adj_close, :exit_date => exit_date,
                       :days_held => days_held, :nomalized_return => normalized_return, #FIXME spelling
                       :risk_factor => risk)
  end

end

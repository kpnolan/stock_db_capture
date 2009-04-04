# == Schema Information
# Schema version: 20090403161440
#
# Table name: positions
#
#  id                   :integer(4)      not null, primary key
#  ticker_id            :integer(4)
#  open                 :boolean(1)
#  entry_date           :datetime
#  exit_date            :datetime
#  entry_price          :float
#  exit_price           :float
#  num_shares           :integer(4)
#  stop_loss            :string(255)
#  strategy_id          :integer(4)
#  days_held            :integer(4)
#  nomalized_return     :float
#  risk_factor          :float
#  week                 :integer(4)
#  population_id        :integer(4)
#  ticker_population_id :integer(4)
#

class Position < ActiveRecord::Base

  include TradingUtils

  has_and_belongs_to_many :scans
  belongs_to :ticker
  belongs_to :strategy

  def self.log_position(population, strategy, ticker, open, entry_date, entry_price, week)
    raise ArgumentError.new("invalid portfolio: #{portfolio}") if (population = TickerPopulation.find_by_name(population)).nil?
    raise ArgumentError.new("invalid strategy: #{strategy}") if (strategy = Strategy.find_by_name(strategy)).nil?

    Position.create!(:ticker_population_id => population.id, :strategy_id => strategy.id, :ticker_id => ticker.id,
                     :entry_price => open, :entry_date => entry_date, :num_shares => 1, :week => week)

  end

  def close_at_max(options={})
    hold_time = options[:hold_time]
    start_date = entry_date
    end_date = trading_to_calendar(start_date, hold_name.end)

    ts = Timeseris.new(ticker_id, start_date..end_date, 1.day,
                       :populate => true, :pre_buffer => false)
    dummy, idx, vecs = ts.rvi(:result => :raw, :noplot => true)
    raise ArgumentError.new("RVi: returned #{vec.length}, expected 1") unless vecs.length == 1
    risk = vecs.first.average
    adj_close_vec = ts.adj_close
    max_adj_close = adj_close_vec.max
    index = adj_close_vec.index(max_adj_close)
    exdate = ts.index2time(index).to_date
    logrs = ts.logr[0..index].sum
    normalized_return = Math.exp(logrs)
    update_attributes!(:exit_price => max_adj_close, :exit_date => exdate,
                       :days_help => index, :normalized_return => normalized_return,
                       :risk_factor => risk)
  end

end

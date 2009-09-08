# == Schema Information
# Schema version: 20090906181342
#
# Table name: positions
#
#  id                  :integer(4)      not null, primary key
#  ticker_id           :integer(4)
#  entry_date          :datetime
#  exit_date           :datetime
#  entry_price         :float
#  exit_price          :float
#  num_shares          :integer(4)
#  stop_loss           :boolean(1)
#  days_held           :integer(4)
#  nreturn             :float
#  scan_id             :integer(4)
#  logr                :float
#  short               :boolean(1)
#  entry_pass          :integer(4)
#  indicator_id        :integer(4)
#  roi                 :float
#  closed              :boolean(1)
#  entry_strategy_id   :integer(4)
#  exit_strategy_id    :integer(4)
#  triggered_at        :datetime
#  trigger_strategy_id :integer(4)
#

#require 'rubygems'
#require 'ruby-debug'

class Position < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :trigger_strategy
  belongs_to :entry_strategy
  belongs_to :exit_strategy
  belongs_to :scan
  belongs_to :indicator

  has_many :position_series, :dependent => :delete_all

  extend TradingCalendar

  def return()
    unless exit_price.nil?
      ((exit_price - entry_price) / entry_price)*100.0
    else
      '-999.99'
    end
  end

  def entry_delay
    Posiion.trading_days_between(entry_date, triggered_at)
  end

  def consumed_margin
    (entry_price - trigger_price)/trigger_price
  end

  class << self

    def trigger(ticker_id, trigger_time, trigger_price, pass, options={})
      begin
        pos = create!(:ticker_id => ticker_id, :trigger_price => trigger_price, :triggered_at => trigger_time, :entry_pass => pass)
      rescue ActiveRecord::RecordInvalid => e
        raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
        raise e
      end
      pos
    end

    def open(position, entry_time, entry_price, options={})
      short = options[:short]
      position.update_attributes!(:entry_price => entry_price, :entry_date => entry_time, :num_shares => 1, :short => short)
      position
    end

    def close(position, exit_date, exit_price, options={})
      days_held = trading_days_between(position.entry_date, exit_date)
      roi = (exit_price - position.entry_price) / position.entry_price
      rreturn = exit_price / position.entry_price
      logr = Math.log(rreturn.zero? ? 0 : rreturn)
      nreturn = days_held.zero? ? 0.0 : roi / days_held
      nreturn *= -1.0 if position.short and nreturn != 0.0
      indicator_id = Indicator.lookup(options[:indicator]).id
      closed = options[:closed]

      position.update_attributes!(:exit_price => exit_price, :exit_date => exit_date, :roi => roi,
                                  :days_held => days_held, :nreturn => nreturn, :indicator_id => indicator_id, :logr => logr,
                                  :closed => closed)
      position
    end
  end
end

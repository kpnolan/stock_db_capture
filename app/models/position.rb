# == Schema Information
# Schema version: 20091029212126
#
# Table name: positions
#
#  id                :integer(4)      not null, primary key
#  ticker_id         :integer(4)
#  ettime            :datetime
#  etprice           :float
#  etival            :float
#  xttime            :datetime
#  xtprice           :float
#  xtival            :float
#  entry_date        :datetime
#  entry_price       :float
#  entry_ival        :float
#  exit_date         :datetime
#  exit_price        :float
#  exit_ival         :float
#  days_held         :integer(4)
#  nreturn           :float
#  logr              :float
#  short             :boolean(1)
#  closed            :boolean(1)
#  entry_pass        :integer(4)
#  roi               :float
#  num_shares        :integer(4)
#  etind_id          :integer(4)
#  xtind_id          :integer(4)
#  entry_trigger_id  :integer(4)
#  entry_strategy_id :integer(4)
#  exit_trigger_id   :integer(4)
#  exit_strategy_id  :integer(4)
#  scan_id           :integer(4)
#

#require 'rubygems'
#require 'ruby-debug'

class Position < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :entry_trigger
  belongs_to :exit_trigger
  belongs_to :entry_strategy
  belongs_to :exit_strategy
  belongs_to :scan
  belongs_to :etind, :class_name => 'Indicator'
  belongs_to :xtind, :class_name => 'Indicator'
  has_many :position_series, :dependent => :delete_all

  named_scope :cheap15, :conditions => { :entry_price => (1.0..15.0) }
  named_scope :cheap30, :conditions => { :entry_price => (1.0..30.0) }
  named_scope :normal, :order => 'entry_price asc'
  named_scope :loser, :order => 'roi asc'
  named_scope :winner, :order => 'roi desc'

  extend TradingCalendar

  def entry_delay
    Position.trading_days_between(entry_date, ettime)
  end

  def xtdays_held
    Position.trading_days_between(entry_date, xttime)
  end

  def xtroi
    (xtprice - entry_price) / entry_price
  end

  def exit_delta
    exit_price - xtprice
  end

  def exit_days_held
    Position.trading_days_between(xttime, exit_date)
  end

  class << self

    def pool_size_on_date(clock)
      count(:conditions => ['date(entry_date) = ?', clock.to_date])
    end

    def trigger_entry(ticker_id, trigger_time, trigger_price, ind_id, ival, pass, options={})
      begin
        pos = create!(:ticker_id => ticker_id, :etprice => trigger_price, :ettime => trigger_time, :entry_pass => pass, :etind_id => ind_id, :etival => ival)
      rescue ActiveRecord::RecordInvalid => e
        raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
        raise e
      end
      pos
    end

    def trigger_exit(position, trigger_time, trigger_price, indicator, ival, options={})
      begin
        ind_id = indicator.nil? ? nil : Indicator.lookup(indicator).id
        closed = options[:closed]
        ival = nil if ival.nil? or ival.nan?
        pos = position.update_attributes!(:xtprice => trigger_price, :xttime => trigger_time, :xtind_id => ind_id, :xtival => ival, :closed => closed)
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

    def close(position, exit_date, exit_price, exit_ival, options={})
      days_held = trading_days_between(position.entry_date, exit_date)
      roi = (exit_price - position.entry_price) / position.entry_price
      rreturn = exit_price / position.entry_price
      logr = Math.log(rreturn.zero? ? 0 : rreturn)
      nreturn = days_held.zero? ? 0.0 : roi / days_held
      nreturn *= -1.0 if position.short and nreturn != 0.0
      closed = options[:closed] == false ? nil : options[:closed]
      indicator_id = Indicator.lookup(options[:indicator]).id

      position.update_attributes!(:exit_price => exit_price, :exit_date => exit_date, :roi => roi,
                                  :xtind_id => indicator_id, :exit_ival => exit_ival,
                                  :days_held => days_held, :nreturn => nreturn, :logr => logr,
                                  :closed => closed)
      position
    end

    def exiting_positions(date)
      find(:all, :conditions => ['date(positions.exit_date) = ?', date.to_date])
    end

    def persist()
      Position.connection.execute('drop table if exits btest_positions')
      Position.connection.execute('create table if not exist btest_positions select * from positions where closed = 1')
    end

    def find_by_date(field, date, options={})
      find(:all, { :conditions => ["date(#{field.to_s}) = ?", date]}.merge(options))
    end
  end
end

# == Schema Information
# Schema version: 20100205165537
#
# Table name: positions
#
#  id                :integer(4) not null primary key
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
#  scan_id           :integer(4)
#  consumed_margin   :float
#  eind_id           :integer(4)
#  xind_id           :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'task/rpctypes'
#require 'composite_primary_keys'

class Position < ActiveRecord::Base

#  set_primary_keys :ticker_id, :entry_date#, :etind_id

  belongs_to :ticker
  belongs_to :scan
  belongs_to :etind, :class_name => 'Indicator'
  belongs_to :xtind, :class_name => 'Indicator'
#  has_many :indicator_values, :foreign_key => [:ticker_id, :entry_date]

  named_scope :filtered, lambda { |*pred| { :conditions => pred.first } }
  named_scope :ordered,  lambda { |*sort| { :order => sort.first } }
  named_scope :on_date,  lambda { |clock| { :conditions => ['date(entry_date) = ?', clock.to_date] } }

  extend TradingCalendar
  include Backtest::PositionMixin

  def to_proxy
    Task::RPCTypes::PositionProxy.new(self)
  end

  def is_proxy?
    false
  end

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

  def open_using_values(label)
    @null_result_id ||= Indicator.lookup(:identity).id
    update_attributes!(:entry_date => ettime, :entry_price => etprice, :entry_ival => etival, :eind_id => @null_result_id)
  end

  def default_close()
    close(xttime, xtprice, xtind_id, xtival, :closed => true)
  end
    #
    # open a position that has been previously triggered. Note that because the entry date may have moved from the
    # trigger date this can result in a duplicate opening, for which we check first
    #
  def open(entry_time, entry_price, options={})
    parent = options[:parent]
    short = options[:short]
    cmargin = (entry_price - etprice)/etprice
    xttime = self.xttime
    if entry_time != self.entry_date
      str = Marshal.dump(self)
      self.destroy
      rec = Marshal.load(str)
      attrs = rec.class.column_names.inject({}) { |hash, name| hash[name] = rec.send(name); hash }
      attrs.merge!(:entry_date => entry_time, :entry_price => entry_price, :short => short, :consumed_margin => cmargin, :pid => Process.pid)
      parent.positions.create!(attrs) if parent
    else
      update_attributes(:entry_price => entry_price, :num_shares => 1, :short => short, :consumed_margin => cmargin, :pid => Process.pid)
      self
    end
  end

  def open_using_trigger_values(options={})
    short = options[:short]
    cmargin = 0.0
    attrs = { :entry_price => self.etprice, :entry_ival => self.etival, :eind_id => self.etind_id, :num_shares => 1, :short => short, :consumed_margin => cmargin }
    attrs.merge!(:entry_date => self.ettime) if self.entry_date != self.ettime
    update_attributes!(attrs)
    self
  end

  def exit_using_results(exit_time, exit_price, exit_ind_id, exit_ival)
    update_attributes!({:exit_date => exit_time, :exit_price => exit_price, :exit_ival => exit_ival, :xind_id => exit_ind_id})
  end

  def trigger_exit(trigger_time, trigger_price, indicator, ival, options={})
    begin
      ind_id = indicator.nil? ? nil : indicator.is_a?(Integer) ? indicator : Indicator.lookup(indicator).id
      closed = options[:closed]
      ival = nil if ival.nil? or ival.nan?
      attrs = { :xtprice => trigger_price, :xttime => trigger_time, :xtind_id => ind_id, :xtival => ival, :closed => closed }
      update_attributes!(attrs)
    rescue ActiveRecord::RecordInvalid => e
      raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
    rescue Exception => e
      raise e
    end
    self
  end

  def record_filter_vals(time, price, indicator, ival, options = { })
    ind_id = indicator.nil? ? nil : Indicator.lookup(indicator).id
    attrs = { :filter_time => time, :filter_price => price, :filter_ival => ival, :filter_id => ind_id }
    update_attributes!(attrs)
  end

  def close(exit_date, exit_price, exit_ind, exit_ival, options={})
    options.reverse_merge! :closed => true
    days_held = Position.trading_days_between(entry_date, exit_date)
    exit_status = if exit_price.nil?
                    roi = rreturn = logr = nreturn = 0.0
                    true
                  else
                    roi = (exit_price - entry_price) / entry_price
                    rreturn = exit_price / entry_price
                    logr = Math.log(rreturn.zero? ? 0.0 : rreturn)
                    nreturn = days_held.zero? ? 0.0 : roi / days_held
                    nreturn *= -1.0 if short and nreturn != 0.0
                    false
                  end
    closed = options[:closed] == false ? nil : options[:closed]
    indicator_id = exit_ind.is_a?(Symbol) ? Indicator.lookup(exit_ind).id : exit_ind

    update_attributes!(:exit_price => exit_price, :exit_date => exit_date,:xind_id => indicator_id, :exit_ival => exit_ival,
                       :roi => roi, :days_held => days_held, :nreturn => nreturn, :logr => logr, :closed => closed)
    exit_status
  end

  class << self
    #
    # Trigger and entry event which does not necessarly mean an entry, that is later confirmed. Since positions are not a composite key
    # a dummy entry date is given to the MySql happy
    #
    def trigger_entry(ticker_id, trigger_time, trigger_price, ind_id, ival, pass, options={})
      begin
        attrs = { :ticker_id => ticker_id, :etprice => trigger_price, :ettime => trigger_time, :entry_pass => pass, :etind_id => ind_id, :etival => ival, :entry_date => trigger_time }
        attrs.merge!(:entry_price => trigger_price) if options[:next_block].nil?
        pos = create!(attrs)
      rescue ActiveRecord::RecordInvalid => e
        raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
      end
      pos
    end

    def trigger_entry_and_open(ticker_id, trigger_time, trigger_price, ind_id, ival, pass, options={})
      begin
        short = options[:short]
        cmargin = 0.0
        attrs = { :ticker_id => ticker_id, :etprice => trigger_price, :ettime => trigger_time,:etind_id => ind_id, :etival => ival,
          :entry_date => trigger_time, :entry_price => trigger_price, :entry_ival => ival, :eind_id => ind_id,
          :num_shares => 1, :short => short, :consumed_margin => cmargin, :entry_pass => pass }
        pos = create!(attrs)
      rescue ActiveRecord::RecordInvalid => e
        raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
      end
      pos
    end

    def exiting_positions(date)
      find(:all, :conditions => ['date(positions.exit_date) = ?', date.to_date])
    end

    def generate_insert_sql(src_model, conditions=nil)
      src = src_model.table_name
      names = columns.map(&:name)
      names.delete('id')
      lhs_names = rhs_names = names
      lhs_cols = lhs_names.join(',')
      rhs_cols = rhs_names.join(',')
      if conditions
        where_clause = "WHERE #{conditions}"
      else
        where_clause = ''
      end
      "insert into #{table_name}(#{lhs_cols}) select #{rhs_cols} from #{src} #{where_clause}"
    end

    def generate_extract_sql(src, dest, filter)
      names = columns.map(&:name)
      names.delete('id')
      lhs_names = rhs_names = names
      if filter.include? 'volume'
        append_clause = 'and (daily_bars.ticker_id = #{src}.ticker_id and daily_bars.bardate = date(entry_date))'
        other_table = ',daily_bars'
        rhs_names << 'daily_bars.volume'
      else
        other_table = ''
        names.delete('volume')
      end
      where = 'where entry_price > 1.0'
      lhs_cols = lhs_names.join(',')
      rhs_cols = rhs_names.join(',')

      "insert into #{dest}(#{lhs_cols}) select #{rhs_cols} from #{src}#{other_table} #{where} #{append_clause}"
    end

    def find_by_date(field, date, options={})
      find(:all, { :conditions => ["date(#{field.to_s}) = ?", date]}.merge(options))
    end

    def find_joined_by_date(field, date, options={})
      join = "JOIN daily_bars ON (daily_bars.ticker_id = #{Positions.table_name}.ticker_id AND " +
        "daily_bars.bardate = DATE(#{Positions.table_name}.entry_date))"
      find(:all, { :join => join, :conditions => ["date(#{field.to_s}) = ?", date]}.merge(options))
    end
  end
end

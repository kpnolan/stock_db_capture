# == Schema Information
# Schema version: 20100205165537
#
# Table name: positions
#
#  ticker_id         :integer(4)      default(0), not null
#  ettime            :datetime
#  etprice           :float
#  etival            :float
#  xttime            :datetime
#  xtprice           :float
#  xtival            :float
#  entry_date        :datetime        not null
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
#  consumed_margin   :float
#  eind_id           :integer(4)
#  xind_id           :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'composite_primary_keys'

class Position < ActiveRecord::Base

  set_primary_keys :ticker_id, :entry_date

  belongs_to :ticker
  belongs_to :entry_trigger
  belongs_to :exit_trigger
  belongs_to :entry_strategy
  belongs_to :exit_strategy
  belongs_to :scan
  belongs_to :etind, :class_name => 'Indicator'
  belongs_to :xtind, :class_name => 'Indicator'
  has_many :indicator_values, :foreign_key => [:ticker_id, :entry_date]

  named_scope :filtered, lambda { |*pred| { :conditions => pred.first } }
  named_scope :ordered,  lambda { |*sort| { :order => sort.first } }
  named_scope :on_date,  lambda { |clock| { :conditions => ['date(entry_date) = ?', clock.to_date] } }

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

    def trigger_entry(ticker_id, trigger_time, trigger_price, ind_id, ival, pass, options={})
      begin
        attrs = { :ticker_id => ticker_id, :etprice => trigger_price, :ettime => trigger_time, :entry_pass => pass, :etind_id => ind_id, :etival => ival, :entry_date => trigger_time }
        attrs.merge!(:entry_price => trigger_price) if options[:next_pass] == false
        pos = create!(attrs)
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
        attrs = { :xtprice => trigger_price, :xttime => trigger_time, :xtind_id => ind_id, :xtival => ival, :closed => closed }
        attrs.merge!(:exit_price => trigger_price, :exit_date => trigger_time)
        pos = position.update_attributes! attrs
      rescue ActiveRecord::RecordInvalid => e
        raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
        raise e
      end
      pos
    end

    #
    # open a position that has been previously triggered. Note that because the entry date may have moved from the
    # trigger date this can result in a duplicate opening, for which we check first
    #
    def open(position, entry_time, entry_price, options={})
      short = options[:short]
      cmargin = (entry_price - position.etprice)/position.etprice
      position.update_attributes!(:entry_price => entry_price, :entry_date => entry_time,
                                  :num_shares => 1, :short => short, :consumed_margin => cmargin)
      position
    end

    def close(position, exit_date, exit_price, exit_ival, options={})
      days_held = trading_days_between(position.entry_date, exit_date)
      exit_status = if exit_price.nil?
                      roi = rreturn = logr = nreturn = 0.0
                      true
                    else
                      roi = (exit_price - position.entry_price) / position.entry_price
                      rreturn = exit_price / position.entry_price
                      logr = Math.log(rreturn.zero? ? 0.0 : rreturn)
                      nreturn = days_held.zero? ? 0.0 : roi / days_held
                      nreturn *= -1.0 if position.short and nreturn != 0.0
                      false
                    end
      closed = options[:closed] == false ? nil : options[:closed]
      indicator_id = Indicator.lookup(options[:indicator]).id

      position.update_attributes!(:exit_price => exit_price, :exit_date => exit_date, :roi => roi,
                                  :xtind_id => indicator_id, :exit_ival => exit_ival,
                                  :days_held => days_held, :nreturn => nreturn, :logr => logr,
                                  :closed => closed)
      exit_status
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

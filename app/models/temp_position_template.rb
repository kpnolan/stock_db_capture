#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
# == Schema Information
# Schema version: 20100205165537
#
# Table name: temp_position_template
#
#  id              :integer(4)      not null, primary key
#  ticker_id       :integer(4)
#  ettime          :date
#  etprice         :float
#  etival          :float
#  xttime          :date
#  xtprice         :float
#  xtival          :float
#  entry_date      :date
#  entry_price     :float
#  entry_ival      :float
#  exit_date       :date
#  exit_price      :float
#  exit_ival       :float
#  days_held       :integer(4)
#  nreturn         :float
#  entry_pass      :integer(4)
#  roi             :float
#  consumed_margin :float
#  volume          :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class TempPositionTemplate < ActiveRecord::Base
  set_table_name 'temp_position_template'

  belongs_to :ticker

  named_scope :filtered,  lambda { |*pred| { :conditions => pred.first } }
  named_scope :ordered,   lambda { |*sort| { :order => sort.first } }
  named_scope :on_entry,  lambda { |clock| { :conditions => { :entry_date => clock.to_date } } }

  KEYWORDS = %{and or not null AND OR NOT NULL }

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
    self.trading_days_between(xttime, exit_date)
  end

  class << self

    def exiting_positions(date)
      find(:all, :conditions => {:exit_date => date.to_date})
    end

    def generate_extract_sql(src, dest, filter)
      names = columns.map(&:name)
      names.shift                       # remote id column
      lhs_names = names
      rhs_names = names.dup
      if filter.include? 'volume'
        append_clause = "and (daily_bars.ticker_id = #{src}.ticker_id and daily_bars.bardate = date(entry_date))"
        other_table = ',daily_bars'
        rhs_names.shift                     # remove ticker_id and...
        rhs_names.unshift(src+'.ticker_id') # replace with scoped column
        rhs_names.delete('volume')
        rhs_names << 'daily_bars.volume'
      else
        other_table = ''
        lhs_names.delete('volume')
        rhs_names.delete('volume')
      end
      order = 'order by entry_date, ticker_id'
      where = 'where ' + filter.split(' ').map do |token|
        case
        when token == 'volume' then 'daily_bars.volume'
        when KEYWORDS.include?(token) then token
        when token =~ /[a-zA-Z]+/ then (src + '.' + token)
        else token
        end
      end.join(' ')
      lhs_cols = lhs_names.join(',')
      rhs_cols = rhs_names.join(',')

      "insert into #{dest}(#{lhs_cols}) select #{rhs_cols} from #{src}#{other_table} #{where} #{append_clause} #{order}"
    end

    def create_temp_table(filter)
      connection.execute("set tmp_table_size=#{2**26}")
      connection.execute("set max_heap_table_size=#{2**26}")
      sql = generate_extract_sql(Position.table_name, 'temp_positions', filter)
      connection.execute("DROP TABLE IF EXISTS temp_positions")
      connection.execute('CREATE TEMPORARY TABLE temp_positions LIKE temp_position_template')
      connection.execute('ALTER TABLE temp_positions ENGINE=MEMORY')
      connection.execute(sql)
      set_table_name 'temp_positions'
    end

    def find_by_date(field, date, options={})
      find(:all, { :conditions => ["#{field.to_s} = ?", date]}.merge(options))
    end
  end
end

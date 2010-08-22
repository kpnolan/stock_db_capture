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
# Table name: tda_positions
#
#  id            :integer(4)      not null, primary key
#  ticker_id     :integer(4)
#  entry_price   :float
#  exit_price    :float
#  curr_price    :float
#  entry_date    :date
#  exit_date     :date
#  num_shares    :integer(4)
#  days_held     :integer(4)
#  nreturn       :float
#  rreturn       :float
#  opened_at     :datetime
#  closed_at     :datetime
#  updated_at    :datetime
#  com           :boolean(1)
#  watch_list_id :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class TdaPosition < ActiveRecord::Base
  belongs_to :ticker
  belongs_to  :watch_list, :dependent => :destroy

  extend TradingCalendar

  validates_presence_of :entry_date, :entry_price, :num_shares, :curr_price, :days_held, :opened_at
#  validates_presence_of :nreturn, :rreturn
  validates_numericality_of :num_shares
#  validates_presence_of :exit_price, :exit_date, :unless => lambda { |tda| tda.closed_at.nil? }
  validates_associated :watch_list, :if => lambda { |tda| tda.closed_at.nil? }

  def after_save()
    watch_list.save! unless watch_list.nil?
  end

  def update_price(current_price)
    update_attribute(:curr_price, current_price)
  end

  def close(price, time)
  end

  def symbol
    ticker.symbol
  end

  def name
    ticker.name
  end

  def roi()
    if closed_at
      (exit_price - entry_price) / entry_price * 100
    elsif watch_list && watch_list.price && entry_price
      (watch_list.price - entry_price) / entry_price * 100.0
    else
      -0.0
    end
  end

  def profit
    @profie ||= if closed_at
                  num_shares * exit_price - num_shares * entry_price
                elsif watch_list && watch_list.price && entry_price
                  num_shares * watch_list.price -  num_shares * entry_price
                else
                  -0.0
                end
  end

  class << self
    def synchronize_with_watch_list
      all.each do |tda|
        tda.days_held = tda.closed_at ? trading_day_count(tda.entry_date, tda.exit_date, false) : trading_day_count(tda.entry_date, Date.today, false)
        tda.curr_price = tda.watch_list && tda.watch_list.price || -0.0
        tda.rreturn = tda.roi
        tda.nreturn = tda.rreturn && tda.days_held != 0 && tda.rreturn / tda.days_held || -0.0
        tda.save!
      end
    end
  end
end

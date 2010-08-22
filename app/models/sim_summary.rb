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
# Table name: sim_summaries
#
#  id                  :integer(4)      not null, primary key
#  sim_date            :date
#  positions_held      :integer(4)
#  positions_available :integer(4)
#  portfolio_value     :float
#  cash_balance        :float
#  pos_opened          :integer(4)
#  pos_closed          :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class SimSummary < ActiveRecord::Base

  validates_presence_of :sim_date, :positions_held, :positions_available, :portfolio_value, :cash_balance, :pos_opened, :pos_closed
  validates_numericality_of :positions_held, :positions_available, :portfolio_value, :cash_balance, :pos_opened, :pos_closed

  class << self
    def truncate()
      connection.execute("truncate #{table_name}")
    end
  end

  def event_time
    sim_date
  end

  # to insert a comma every 3 digits do: n.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
  def to_s()
    pretty_portfolio_value = portfolio_value.round.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    pretty_cash_balance = cash_balance.round.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    pretty_total = (portfolio_value + cash_balance).round.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    format(' $%10s + $%10s = $%10s', pretty_portfolio_value, pretty_cash_balance, pretty_total)
  end
end

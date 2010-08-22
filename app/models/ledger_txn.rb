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
# Table name: ledger_txns
#
#  id       :integer(4)      not null, primary key
#  amount   :float
#  date     :datetime
#  txn_type :integer(4)
#  order_id :integer(4)
#  balance  :float
#  msg      :string(255)
#

# == Schema Information
# Schema version: 20091029212126
#
# Table name: ledger_txns
#
#  id       :integer(4)      not null, primary key
#  amount   :float
#  date     :datetime
#  txn_type :integer(4)
#  order_id :integer(4)
#  balance  :float
#  msg      :string(255)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.
require 'ostruct'

class LedgerTxn < ActiveRecord::Base
  belongs_to :order

  validates_presence_of :date, :balance, :msg
  validates_numericality_of :amount, :balance

  class << self

    def debit(amount, date, balance, order_id, msg)
      attrs = OpenStruct.new
      attrs.amount = amount
      attrs.txn_type = -1
      attrs.date = date
      attrs.order_id = order_id
      attrs.msg = msg
      attrs.balance = balance + (attrs.txn_type)*amount
      obj = create!(attrs.marshal_dump)
    end

    def credit(amount, date, balance, order_id, msg)
      attrs = OpenStruct.new
      attrs.amount = amount
      attrs.txn_type = 1
      attrs.date = date
      attrs.order_id = order_id
      attrs.msg = msg
      attrs.balance = balance + (attrs.txn_type)*amount
      obj = create!(attrs.marshal_dump)
    end

    def truncate()
      connection.execute("truncate #{self.to_s.tableize}")
    end
  end

  def to_s
    crdb = txn_type > 0 ? 'CREDIT' : 'DEBIT '
    format('%s %5.2f BAL: %5.2f %s', crdb, amount*txn_type, balance, msg)
  end

  def event_time
    date
  end
end

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

    def current_balance()
      count.zero? ? -0.0 : last.balance
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

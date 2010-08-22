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

module Sim
  class MoneyMgr < Subsystem

    attr_accessor :current_balance
    attr_reader :minimum_balance, :initial_balance

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @current_balance = 0.0
      @minimum_balance = cval(:minimum_balance)
      @initial_balance = cval(:initial_balance)
    end

    def apply_interest(interest_factor)
      @current_balance *= interest_factor
    end

    def debit(amount, date, options={})
      txn = LedgerTxn.debit(amount, date, current_balance, options[:order_id], options[:msg])
      self.current_balance -= amount
      txn
    end

    def credit(amount, date, options={})
      txn = LedgerTxn.credit(amount, date, current_balance, options[:order_id], options[:msg])
      self.current_balance += amount
      txn
    end

    def funds_available()
      current_balance - minimum_balance
    end
  end
end

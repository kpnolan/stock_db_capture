# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

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

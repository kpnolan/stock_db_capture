module Sim
  class MoneyMgr < Subsystem

    def initialize(sm)
      super(sm, self.class)
    end

    def min_balance(); cval(:min_balance).to_f; end

    def debit(amount, date, options={})
      LedgerTxn.debit(amount, date, options[:order_id], options[:msg])
    end

    def credit(amount, date, options={})
      LedgerTxn.credit(amount, date, options[:order_id], options[:msg])
    end

    def current_balance()
       LedgerTxn.current_balance()
    end

    def funds_available()
      current_balance() - min_balance()
    end
  end
end

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class OrderProcessor < Subsystem

    attr_reader :opened_position_count, :closed_position_count

    def initialize(sm, cm)
      super(sm, cm, self.class)
      daily_hook()
    end

    def daily_hook
      @opened_position_count = 0
      @closed_position_count = 0
    end

    def order_amount(); @oa ||= cval(:order_amount); end
    def order_charge(); @oc ||= cval(:order_charge); end

    def dynamic_buy(position)
      binding = create_binding(position)
    end

    def buy(position)
      if order_amount() < funds_available()
        order = Order.make_buy(position.ticker.id, position.entry_price, clock,
                               :order_ceiling => order_amount, :funds_available => funds_available, :order_charge => order_charge)
        execute(order, :position_id => position.id)
      else
        puts "Not enough cash to BUY: #{order_amount()} > #{funds_available()}"
      end
    end

    def execute(order, options={})
      msg = format('%d shares of %s@%3.2f per share', order.quantity, order.symbol, order.fill_price)
      case order.txn
      when 'BUY' then
        txn = debit(order.order_price, clock, :order_id => order.id, :msg => msg )
        order.save!
        sim_position = SimPosition.open(order, options)
        @opened_position_count += 1
        log_event(order)
        log_event(txn)
        log_event(sim_position)
        #sep()
      when 'SEL'
        txn = credit(order.order_price, clock, :order_id => order.id, :msg => msg)
        order.save!
        @closed_position_count += 1
        log_event(order)
        log_event(txn)
        order.sim_position.close(order)
        log_event(order.sim_position)
        #sep()
      end
    end

    def sell(sim_position)
      order = if sim_position.position.exit_date.to_date == sysdate()
        sell_at_maturity(sim_position)
      else
        sell_premature(sim_position)
      end
      execute(order)
    end

    def sell_at_maturity(sim_position)
      Order.make_sell(sim_position, sim_position.position.exit_price, clock, :order_charge => order_charge)
    end

    def sell_premature(sim_position)
      ticker_id = sim_position.position.ticker_id
      #TODO grap the current price from dailybars
    end
  end
end

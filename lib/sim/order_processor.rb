module Sim
  class OrderProcessor < Subsystem

    def initialize(sm, cm)
      super(sm, cm, self.class)
    end

    def min_order_amount(); @moa ||= cval(:min_order_amount).to_f; end
    def max_order_amount(); @xoa ||= cval(:max_order_amount).to_f; end
    def order_charge(); @oc ||= cval(:order_charge).to_f; end

    def buy(position)
      if min_order_amount() < funds_available()
        order = Order.make_buy(position.ticker.id, position.entry_price, clock,
                               :order_ceiling => max_order_amount, :funds_available => funds_available, :order_charge => order_charge)
        execute(order, :position_id => position.id)
        inc_opened_positions()
      else
        puts "No BUY: #{min_order_amount()} > #{funds_available()}"
      end
    end

    def execute(order, options={})
      msg = format('%d shares of %s@%3.2f per share', order.quantity, order.symbol, order.fill_price)
      case order.txn
      when 'BUY' then
        txn = debit(order.order_price, clock, :order_id => order.id, :msg => msg )
        order.save!
        sim_position = SimPosition.open(order, options)
        $el.log_event(order)
        $el.log_event(txn)
        $el.log_event(sim_position)
        #$el.sep
      when 'SEL'
        txn = credit(order.order_price, clock, :order_id => order.id, :msg => msg)
        order.save!
        $el.log_event(order)
        $el.log_event(txn)
        order.sim_position.close(order)
        $el.log_event(order.sim_position)
        #$el.sep
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

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class PortfolioMgr < Subsystem

    attr_reader :min_balance, :reinvest_factor, :order_limit, :portfolio_size

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @reinvest_factor = cval(:reinvest_percent) / 100.0
      @portfolio_size = cval(:portfolio_size)
    end

    def post_dispatch_hook()
      @min_balance = minimum_balance()
      @order_limit = max_order_amount()
    end

    def open_position_count()
      SimPosition.open_position_count()
    end

    def open_positions()
      SimPosition.open_positions()
    end

    def mature_positions()
      SimPosition.exiting_positions(sysdate())
    end

    def pool_size()
      Position.normal.pool_size_on_date(sysdate())
    end

    def num_vacancies()
      if current_balance() > min_balance
        [current_balance() * reinvest_factor / order_limit,  portfolio_size - open_position_count(), 0].max
      else
        0
      end
    end

    def market_value(date)
      sql = "select sum(close*quantity) from sim_positions join daily_bars using(ticker_id) where bardate = '#{date.to_s(:db)}' and exit_date is null"
      SimPosition.connection.select_value(sql).to_f
    end
  end
end

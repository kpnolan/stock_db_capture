module Sim
  class PortfolioMgr < Subsystem

    def initialize(sm)
      super(sm, self.class)
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
      Position.pool_size_on_date(sysdate())
    end

    def max_portfolio_size()
      cval(:portfolio_size).to_i
    end

    def num_vacancies()
      max_portfolio_size() - open_position_count()
    end

    def market_value(date)
      sql = "select sum(close*quantity) from sim_positions join daily_bars using(ticker_id) where bardate = '#{date.to_s(:db)}' and exit_date is null"
      SimPosition.connection.select_value(sql).to_f
    end
  end
end

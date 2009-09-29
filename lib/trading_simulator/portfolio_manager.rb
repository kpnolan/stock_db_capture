require 'singleton'


module TradingSimulator
  class PortfolioManager < Struct.new(:position_min, :position_max, :system_manager)

    include Singleton

    def initialize(options)
      super(options[:min_inventory], options[:max_inventory], options[:system_manager])
    end

    def daily_rounds()
      close_expiring_positions(system_manager.simulation_date())
      if position_count() < position_min
        tickers = look_for_opportunities(position_shortfall())
        create_buy_orders(tickers)
      end
    end

    def close_expiring_positions(date)
      SimPosition.expiring_positions(date).each do |position|
        create_sell_order(position)
      end
    end

    def position_count()
      SimPosition.open_position_count()
    end

    def look_for_opportunities(count)
      system_manager.position_selector.find_positions(count)
    end

    def create_sell_order(position)
      system_manager.order_factory.create_sell_order(position)
    end

    def create_by_orders(tickers)
      tickers.eaach do |ticker|
        system_manager.order_factory.create_by_order(ticker)
      end
    end

    def position_shortfall()

    end
  end

end

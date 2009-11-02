require 'ostruct'

module Sim
  class SystemMgr

    extend TradingCalendar
    extend Forwardable
    include CurrentMethod

    def_delegators :@cm, :config_hash
    def_delegators :@op, :buy, :sell
    def_delegators :@mm, :credit, :debit, :funds_available, :current_balance
    def_delegators :@pm, :open_positions, :open_position_count, :mature_positions, :pool_size, :num_vacancies, :market_value
    def_delegators :@ch, :find_candidates
    def_delegators :@pc, :sell_mature_positions

    attr_reader :config, :subsystems, :clock, :logger, :start_date, :end_date

    def initialize()
      @subsystems = []
      @subsystems << @cm = ConfigurationMgr.new(self) # must be first!!
      @subsystems << @pm = PortfolioMgr.new(self)
      @subsystems << @op = OrderProcessor.new(self)
      @subsystems << @mm = MoneyMgr.new(self)
      @subsystems << @ch = Chooser.new(self)
      @subsystems << @pc = PositionCloser.new(self)

      @config = config_hash(self.class)
      @logger =  ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'simulator.log'))

      @start_date = cval(:start_date).to_date
      @end_date = cval(:end_date).to_date
      @clock = start_date.to_time.localtime.change(:hour => 6, :min => 30)

      $el = EventLogger.instance()

      db_init()
    end

    def db_init()
      if current_balance == -0.0
        initial_amount = @cm.raw_cval(MoneyMgr, :initial_balance)
        credit(initial_amount, clock, :msg => "Initial Balance")
      end
    end

    def cval(key)
      config[key.to_s]
    end

    def increment_date()
      attrs = OpenStruct.new()
      attrs.sim_date = sysdate()
      attrs.positions_held = open_position_count()
      attrs.positions_available = pool_size()
      attrs.portfolio_value = market_value(sysdate()).round
      attrs.cash_balance = current_balance().round
      SimSummary.create! attrs.marshal_dump
      @clock = SystemMgr.trading_date_from(clock, 1)
    end

    def sysdate()
      clock.to_date
    end

    def update_config()
      subsystems.each { |sub| sub.init_config() }
    end

    def sim_loop()
      while sysdate < end_date do
        sell_mature_positions()
        candidates = find_candidates(sysdate, num_vacancies())
        candidates.each { |candidate| buy(candidate) }
        increment_date()
      end
    end

    def total_value()
      market_value() + current_balance()
    end

    def info(subsystem, method, msg)
      logger.info("#{subsystem}:#{method} -- #{msg}")
    end

    def error(subsystem, method, msg)
      logger.error("!!!#{subsystem}:#{method} -- #{msg}")
    end

    class << self
      def reset()
        SimPosition.connection.execute("SET FOREIGN_KEY_CHECKS = 0")
        SimSummary.truncate
        SimPosition.truncate
        LedgerTxn.truncate
        Order.truncate
        SimPosition.connection.execute("SET FOREIGN_KEY_CHECKS = 1")
      end

      def run()
        reset()
        sysmgr = SystemMgr.new()
        sysmgr.sim_loop()
      end
    end
  end
end

require 'ostruct'

module Sim
  class SystemMgr

    extend TradingCalendar
    extend Forwardable
    include CurrentMethod

    def_delegators :@op, :buy, :sell, :max_order_amount
    def_delegators :@mm, :credit, :debit, :funds_available, :current_balance, :minimum_balance, :initial_balance
    def_delegators :@pm, :open_positions, :mature_positions, :pool_size, :num_vacancies, :market_value, :open_position_count
    def_delegators :@ch, :find_candidates
    def_delegators :@pc, :sell_mature_positions

    attr_reader   :config, :subsystems, :clock, :logger, :start_date, :end_date, :positions_opened, :positions_closed
    attr_accessor :positions_closed, :positions_opened
    attr_accessor :cm, :sm, :op, :mm, :pm, :ch, :pc

    def initialize()
      self.cm = ConfigurationMgr.new # must be first!!
      @config = cm.config_hash(self.class)

      @subsystems = []
      @subsystems << self.pm = PortfolioMgr.new(self, cm)
      @subsystems << self.op = OrderProcessor.new(self, cm)
      @subsystems << self.mm = MoneyMgr.new(self, cm)
      @subsystems << self.ch = Chooser.new(self, cm)
      @subsystems << self.pc = PositionCloser.new(self, cm)

      subsystems.each { |ss| ss.init_dispatch() }
      subsystems.each { |ss| ss.post_dispatch_hook() if ss.respond_to? :post_dispatch_hook }

      @logger =  ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'simulator.log'))

      @start_date = cval(:start_date).to_date
      @end_date = cval(:end_date).to_date
      @clock = start_date.to_time.localtime.change(:hour => 6, :min => 30)

      log_levels = cval(:log).map { |name| name.constantize }
      $el = EventLogger.instance()
      $el.set_levels(log_levels)

      db_init()
    end

    def reset_daily_stats()
      self.positions_closed, self.positions_opened = 0, 0
    end

    def inc_opened_positions()
      self.positions_opened += 1
    end

    def db_init()
      credit(initial_balance(), clock, :msg => "Initial Balance")
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
      attrs.pos_opened = positions_opened
      attrs.pos_closed = positions_closed
      sum = SimSummary.create! attrs.marshal_dump
      $el.log_event(sum)
      self.positions_opened += positions_opened
      self.positions_closed += positions_closed
      @clock = SystemMgr.trading_date_from(clock, 1)
    end

    def sysdate()
      clock.to_date
    end

    def update_config()
      subsystems.each { |sub| sub.init_config() }
    end

    # NB! any named scope must be represented in pool_size() and find_candidates()
    def sim_loop()
      while sysdate < end_date do
        reset_daily_stats()
        self.positions_closed = sell_mature_positions()
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
        $el.log_event("Positions Opened: #{positions_opened}")
        $el.log_event("Positions Closed: #{positions_closed}")
      end
    end
  end
end

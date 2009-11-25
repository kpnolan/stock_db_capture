# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'ostruct'

module Sim

  def Sim.run(options)
    SystemMgr.run(options)
  end

  class SystemMgr

    extend TradingCalendar
    extend Forwardable
    include CurrentMethod

    def_delegators :@op, :buy, :sell, :max_order_amount, :opened_position_count, :closed_position_count
    def_delegators :@mm, :credit, :debit, :funds_available, :current_balance, :minimum_balance, :initial_balance
    def_delegators :@pm, :open_positions, :mature_positions, :pool_size, :num_vacancies, :market_value, :open_position_count
    def_delegators :@ch, :find_candidates
    def_delegators :@pc, :sell_mature_positions
    def_delegators :@rg, :generate_reports

    attr_reader   :config, :subsystems, :clock, :logger, :start_date, :end_date, :population
    attr_reader :total_opened, :total_closed
    attr_accessor :cm, :sm, :op, :mm, :pm, :ch, :pc, :rg

    def initialize(options)
      prefix = options.prefix ? options.prefix+'_' : ''

      @logger =  ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', prefix+'simulator.log'))

      self.cm = ConfigurationMgr.new(self, options) # must be first!!

      @subsystems = []
      @subsystems << self.pm = PortfolioMgr.new(self, cm)
      @subsystems << self.op = OrderProcessor.new(self, cm)
      @subsystems << self.mm = MoneyMgr.new(self, cm)
      @subsystems << self.ch = Chooser.new(self, cm)
      @subsystems << self.pc = PositionCloser.new(self, cm)
      @subsystems << self.rg = ReportGenerator.new(self, cm)

      subsystems.each { |ss| ss.init_dispatch() }
      subsystems.each { |ss| ss.post_dispatch_hook() if ss.respond_to? :post_dispatch_hook }

      @start_date = cval(:start_date).to_date
      @end_date = cval(:end_date).to_date
      @clock = start_date.to_time.localtime.change(:hour => 6, :min => 30)
      @population = cval(:position_table)
      raise ArgumentError, "population was not specified in on the command line or defaulted" if population.nil?

      @total_opened, @total_closed = 0,0
      $el = EventLogger.new(cm)

      db_init()
    end

    def reset_daily_stats()
      @total_opened += opened_position_count
      @total_closed += closed_position_count
      subsystems.each { |ss| ss.daily_hook() if ss.respond_to? :daily_hook }
    end

    def db_init()
      count = Position.filtered(cval(:filter_predicate)).ordered(cval(:sort_by)).count
      puts "#{count} positions matched filtering criteria"
      tables = Position.connection.select_values('show tables')
      raise ArgumentError, "unknown positions table #{population}_positions" unless tables.include? "#{population}_positions"
      Position.set_table_name(population + '_positions')
      credit(initial_balance(), clock, :msg => "Initial Balance")
      SimPosition.connection.execute('CREATE TEMPORARY TABLE temp_sim_positions LIKE sim_positions')
      SimPosition.set_table_name 'temp_sim_positions'
      SimSummary.connection.execute('CREATE TEMPORARY TABLE temp_sim_summaries LIKE sim_summaries')
      SimSummary.set_table_name 'temp_sim_summaries'
    end

    def cval(key)
      cm.cval(key)
    end

    def increment_date()
      attrs = OpenStruct.new()
      attrs.sim_date = sysdate()
      attrs.positions_held = open_position_count()
      attrs.positions_available = pool_size()
      attrs.portfolio_value = market_value(sysdate()).round
      attrs.cash_balance = current_balance().round
      attrs.pos_opened = opened_position_count
      attrs.pos_closed = closed_position_count
      sum = SimSummary.create! attrs.marshal_dump
      $el.log_event(sum)
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
        reset_daily_stats()
        sell_mature_positions()
        candidates = find_candidates(sysdate, num_vacancies())
        candidates.each { |candidate| buy(candidate) }
        increment_date()
      end
    end

    # If --keep was supplied on the command line, copy the sim_summaries and sim_positions tables to
    # a tables formed by either the prefix (if supplied) or the source table name. Raise and exception
    # of no prefix can be computed
    def post_processing()
      if cval(:keep_tables)
        names = case
                when cval(:prefix) then
                  ["#{cval(:prefix)}_sim_summaries", "#{cval(:prefix)}_sim_positions"]
                when cval(:position_table) then
                  ["#{cval(:position_table)}_sim_summaries", "#{cval(:position_table)}_sim_positions"]
                else
                  raise ArgumentError, "--keep specified but no effective prefix can be found"
                end
        dest_sum_table, dest_pos_table = names
        SimSummary.connection.execute("DROP TABLE IF EXISTS #{dest_sum_table}")
        SimPosition.connection.execute("DROP TABLE IF EXISTS #{dest_pos_table}")
        SimSummary.connection.execute("CREATE TABLE #{dest_sum_table} LIKE #{SimSummary.table_name}")
        SimPosition.connection.execute("CREATE TABLE #{dest_pos_table} LIKE #{SimPosition.table_name}")
        SimSummary.connection.execute("INSERT INTO #{dest_sum_table} SELECT * FROM #{SimSummary.table_name}")
        SimPosition.connection.execute("INSERT INTO #{dest_pos_table} SELECT * FROM #{SimPosition.table_name}")
      end
    end

    def total_value()
      market_value() + current_balance()
    end

    def log(msg)
      logger.info(msg)
      logger.flush()
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

      def run(options)
        reset()
        sysmgr = SystemMgr.new(options)
        sysmgr.sim_loop()
        sysmgr.generate_reports()
        sysmgr.post_processing()
        sysmgr.log("Total Positions Opened: #{sysmgr.total_opened}")
        sysmgr.log("Total Positions Closed: #{sysmgr.total_closed}")
      end
    end
  end
end

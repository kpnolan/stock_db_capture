module Sim
  class Subsystem

    extend Forwardable
    include CurrentMethod

    def_delegators :@system_mgr, :clock, :sysdate, :error, :info
    def_delegators :@system_mgr, :config_hash
    def_delegators :@system_mgr, :buy, :sell
    def_delegators :@system_mgr, :credit, :debit, :funds_available, :current_balance
    def_delegators :@system_mgr, :open_positions, :mature_positions, :pool_size, :num_vacancies, :market_value
    def_delegators :@system_mgr, :sell_mature_positions

    attr_reader :system_mgr, :config

    def initialize(sm, klass)
      @system_mgr = sm
      @subclass = klass
      init_config()
    end

    def init_config()
      @config = system_mgr.config_hash(@subclass)
    end

    def cval(key)
      config[key.to_s]
    end

    def info(msg)
      @system_mgr.info(@subclass, calling_method(), msg)
    end

    def error(msg)
      @system_mgr.error(@subclass, calling_method(), msg)
    end
  end
end

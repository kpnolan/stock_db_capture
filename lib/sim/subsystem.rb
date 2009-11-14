module Sim
  class Subsystem

    extend Forwardable
    include CurrentMethod

    attr_accessor :sm, :cm, :op, :mm, :pm, :ch, :pc

    def_delegators :@sm, :clock, :sysdate, :error, :info, :inc_opened_positions
    def_delegators :@op, :buy, :sell, :max_order_amount
    def_delegators :@mm, :credit, :debit, :funds_available, :current_balance, :minimum_balance
    def_delegators :@pm, :open_positions, :mature_positions, :pool_size, :num_vacancies, :market_value
    def_delegators :@ch, :find_candiates
    def_delegators :@pc, :sell_mature_positions
    def_delegators :@cm, :config_hash

    attr_reader :config

    def initialize(sm, cm, klass)
      self.sm = sm
      self.cm = cm
      @subclass = klass
    end

    def init_dispatch()
      self.pm = sm.pm
      self.op = sm.op
      self.mm = sm.mm
      self.ch = sm.ch
      self.pc = sm.pc
    end

    def config
      @config ||= config_hash(@subclass)
    end

    def cval(key)
      config[key.to_s]
    end

    def info(msg)
      sm.info(@subclass, calling_method(), msg)
    end

    def error(msg)
      sm.error(@subclass, calling_method(), msg)
    end
  end
end

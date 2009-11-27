# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class Subsystem

    extend Forwardable
    include CurrentMethod

    attr_accessor :sm, :cm, :op, :mm, :pm, :ch, :pc, :rg, :el
    attr_reader :subclass

    def_delegators :@sm, :clock, :sysdate, :error, :info, :log, :output_dir
    def_delegators :@op, :buy, :sell, :order_amount
    def_delegators :@mm, :credit, :debit, :funds_available, :current_balance, :minimum_balance
    def_delegators :@pm, :open_positions, :mature_positions, :pool_size, :num_vacancies, :market_value
    def_delegators :@ch, :find_candiates
    def_delegators :@pc, :sell_mature_positions
    def_delegators :@el, :log_event, :sep


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
      self.rg = sm.rg
      self.el = sm.el
    end

    def cval(key)
      cm.cval(key)
    end

    def log(msg)
      sm.log(msg)
    end

    def info(msg)
      sm.info(subclass, calling_method(), msg)
    end

    def error(msg)
      sm.error(subclass, calling_method(), msg)
    end
  end
end

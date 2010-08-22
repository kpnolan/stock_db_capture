#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Sim
  class Subsystem

    extend Forwardable
    include CurrentMethod

    attr_accessor :sm, :cm, :op, :mm, :pm, :ch, :pc, :rg, :el
    attr_reader :subclass

    def_delegators :@sm, :clock, :sysdate, :error, :info, :log, :output_dir
    def_delegators :@op, :buy, :sell, :order_amount
    def_delegators :@mm, :credit, :debit, :funds_available, :current_balance, :minimum_balance
    def_delegators :@pm, :mature_positions, :num_vacancies, :market_value
    def_delegators :@ch, :find_candiates, :pool_size
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

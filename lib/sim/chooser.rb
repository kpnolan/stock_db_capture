# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'set'

module Sim
  class Chooser < Subsystem

    attr_reader :pool_behavior, :include_set, :pool_size

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @include_set = cval(:included_symbols) && Set.new(cval(:included_symbols).map(&:upcase))
    end

    def find_candidates(date, count)
      total_pool = TempPositionTemplate.on_entry(date).ordered(cval(:sort_by))
      @pool_size = total_pool.length
      pool = total_pool.slice!(0, count)
      if include_set
        symbol_set = Set.new(pool.map { |p| p.ticker.symbol })
        intersection = symbol_set & include_set
        pool.delete_if { |p| not intersection.include?(p.ticker.symbol) }
      else
        pool
      end
    end
  end
end

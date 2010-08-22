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

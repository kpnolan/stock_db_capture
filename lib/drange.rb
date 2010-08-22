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
#---------------------------------------------------------------------------------------------------
# DRange -- Discontinuous range. Acts like a range but requires a step parameter to be
#                  given. The class will return values from min to max depending on which is
#                  greater in increments of the step arg up to the limit. Class includes
#                  Enumerable allowing all methods from that module (map, collect, etc..)
#---------------------------------------------------------------------------------------------------
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class DRange
  include Enumerable

  attr_accessor :min, :max, :step, :limit, :cur

  def initialize(min, max, step)
    return ArgumentError, "step cannot be zero!" if step.zero?
    @min, @max, @step = min, max, step
    rewind()
  end

  def each()
    raise ArgumentError, "no block given" unless block_given?
    while cur <= limit
      yield cur
      @cur += step
    end
  end

  def rewind()
    if min > max
      self.step *= -1 if step > 0
      self.cur = max
      self.limit = min
    else
      self.limit = max
      self.cur = min
    end
  end
end

def all_combinations(*enums, &blk)
  enum = enums.map(&:to_a)
  pre = ""
  post = ""
  middle = []
  enum.each_with_index do |en,idx|
    item = "e#{idx}"
    pre << "enum[" << idx.to_s << "].each {|" << item << "| "
    middle << item
    post << "}"
  end
  eval(pre << "blk[" << middle.join(",") << "]" << post)
end

#
# Unit Test -- when run, should generate the commented output
#
if __FILE__ == $0
  all_combinations(DRange.new(20, 30, 5), DRange.new(50, 70, 5)) { |*a| p a}
end

# Should give:

# [20, 50]
# [20, 55]
# [20, 60]
# [20, 65]
# [20, 70]
# [25, 50]
# [25, 55]
# [25, 60]
# [25, 65]
# [25, 70]
# [30, 50]
# [30, 55]
# [30, 60]
# [30, 65]
# [30, 70]

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

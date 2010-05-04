# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'gsl'

# This module is dependent on two methods begin available in the enclosing environment: vector_for and :outidx

# OPTIMIZE We should have two forms of each of this functions: one finds a vector of crossing and the other finds the first one
# OPTIMIZE since when closing a position we are generally interested in the first event as opposed to opening positions where
# OPTIMIZE we want to open positions for every crossing
module ResultAnalysis
  RAD2DEG = (180.0/Math::PI)
  include GSL
  @@threshold_vec_hash = { }

  VALID_OPS = [:gt, :lt, :ge, :le, :eq]

  attr_accessor :mode              # this will be used to optimize the where into first or something

  def ResultAnalysis.tvec_alloc(len, threshold)
    key = [len, threshold]
    return @@threshold_vec_hash[key] if @@threshold_vec_hash.has_key? key
    @@threshold_vec_hash[key] = GSL::Vector.alloc(len).set_all(threshold)
  end

  def ResultAnalysis.memoized_thresholds
    outstr = ''
    @@threshold_vec_hash.keys.each do |key|
      outstr << "threshold: #{key.last} of #{key.first} length\n"
    end
    outstr
  end

  def monotonic_sequence(max, vec)
    index = vec.find_index { |n| n < max || (max = n) && false }
    index.nil? ? :max : index + outidx
  end

  def over_threshold(threshold, vec)
    threshold_crossing(threshold, vec, :gt)
  end

  def under_threshold(threshold, vec)
    threshold_crossing(threshold, vec, :lt)
  end

  def threshold_crossing(threshold, vec, op)
    raise ArgumentError, "#{op} not one of #{VALID_OPS.join(', ')}" unless VALID_OPS.include? op
    tvec = ResultAnalysis.tvec_alloc(vec.len, threshold)
    crossing(op, vec, tvec)
  end

  def crosses_over(a_vec ,b_vec)
    crossing(:gt, a_vec, b_vec)
  end

  def crosses_under(a_vec, b_vec)
    crossing(:lt, a_vec, b_vec)
  end

  def slope_at_crossing(vec1, vec2, crossings)
    raise TimeseriesException, "Vectors are not the same length #{v1.len} versus #{vec2.len}" if vec1.len != vec2.len
    outvec = []
    xvec = GSL::Vector.alloc(-1, 0, 1)
    for crossing in crossings.map { |idx| idx - outidx }
      begin
        vec1_points = vec1[crossing-1..crossing+1]
        vec2_points = vec2[crossing-1..crossing+1]
        slope1 = GSL::Fit.linear(xvec, vec1_points).second
        slope2 = GSL::Fit.linear(xvec, vec2_points).second
#        angle1, angle2 = Math.atan(1/slope1)*RAD2DEG, Math.atan(1/slope2)*RAD2DEG
        outvec << [crossing+outidx, vec1[crossing], compare_slopes(slope1, slope2) ]
      rescue
        next
      end
    end
    outvec
  end

  def compare_slopes(slope1, slope2)
    sign1 = slope1 <=> 0.0
    sign2 = slop2 <=> 0.0
    delta = slope1 - slope2
    case
    when sign2 != sign2 && delta > 0.1 : -1
    when sign1 == sign2 && delta < 0.1 :  0
    else
      1
    end
  end

  #
  # Returns an array of indexes where vector b crosses vector (generally a threshold vector)  the type of crossing is given
  # by the method argument (:gt, :lt, :ge, :le)  which detects upward crossings and downward crossing.
  # NB The indexes return ARE OFFSET by OUTIDX so that a crossing a vec[0] is the point given for the beginning of the
  # timeseries (start_time)
  #
  def crossing(method, a, b)
    bitmap = a.send(method, b)
    lval = (bitmap[0] == 1)
    idx = 0
    indexes = []
    bitmap.where do |bflag|
      flag = (bflag == 1)
      indexes << idx+outidx if (lval ^ flag && !flag)
      lval = flag
      idx += 1
    end
    indexes
  end

  def find_ones(sym)
    vector_for(sym).where { |e| e == 1 }.add_constant!(outidx).to_a
  end
end


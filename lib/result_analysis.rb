# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'gsl'

# This module is dependent on two methods begin available in the enclosing environment: vector_for, outidx

# OPTIMIZE We should have two forms of each of this functions: one finds a vector of crossing and the other finds the first one
# OPTIMIZE since when closing a position we are generally interested in the first event as opposed to opening positions where
# OPTIMIZE we want to open positions for every crossing
module ResultAnalysis

  include GSL

  VALID_OPS = [:gt, :lt, :ge, :le, :eq]

  attr_accessor :mode                                         # this will be used to optimize the where into first or something

  def over_threshold(threshold, sym)
    unless (indexes = threshold_crossing(threshold, sym, :gt)).nil?
      indexes.to_v.to_i.add_constant!(outidx).to_a
    else
      []
    end
  end

  def under_threshold(threshold, sym)
    unless (indexes = threshold_crossing(threshold, sym, :lt)).nil?
      indexes.to_v.to_i.add_constant!(outidx).to_a
    else
      []
    end
  end

  def threshold_crossing(threshold, sym, op)
    raise ArgumentError, "#{op} not one of #{VALID_OPS.join(', ')}" unless VALID_OPS.include? op
    vec = vector_for(sym)
    tvec = GSL::Vector.alloc(vec.len).set_all(threshold)
    crossing(op, vec, tvec)
  end

  def crosses_over(sym1 ,sym2)
    a_vec = vector_for(sym1)
    b_vec = vector_for(sym2)
    crossing(:gt, a_vec, b_vec).to_v.to_i.add_constant!(outidx).to_a
  end

  def crosses_under(sym1, sym2)
    a_vec = vector_for(sym1)
    b_vec = vector_for(sym2)
    crossing(:lt, a_vec, b_vec).to_v.to_i.add_constant!(outidx).to_a
  end

  def crossing(method, a, b)
    bitmap = a.send(method, b)
    last_value = bitmap[0]
    bitmap.where do |bflag|
      result = (last_value == 1 && bflag == 0)
      last_value = bflag
      result
    end
  end

  def find_ones(sym)
    vector_for(sym).where { |e| e == 1 }.add_constant!(outidx).to_a
  end
end


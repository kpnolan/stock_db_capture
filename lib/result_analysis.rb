require 'rubygems'
require 'gsl'

module ResultAnalysis

  include GSL

  VALID_OPS = [:gt, :lt, :ge, :le, :eq]

  def over_threshold(threshold, sym)
    threshold_crossing(threshold, sym, :gt).to_v.to_i.add_constant!(outidx).to_a
  end

  def under_threshold(threshold, sym)
    threshold_crossing(threshold, sym, :lt).to_v.to_i.add_constant!(outidx).to_a
  end

  def threshold_crossing(threshold, sym, op)
    raise ArgumentError, "#{op} not one of #{VALID_OPS.join(', ')}" unless VALID_OPS.include? op
    vec = vector_for(sym)
    tvec = GSL::Vector.alloc(vec.len).set_all(threshold)
    bitmap = vec.send(op, tvec)
    bitmap.where { |bflag| bflag == 1 }
  end

  def crosses_over(sym1 ,sym2)
    a_vec = vector_for(sym1)
    b_vec = vector_for(sym2)
    crossing(:gt, a_vec, b_vec).add_constant!(outidx).to_a
  end

  def crosses_under(sym1, sym2)
    a_vec = vector_for(sym1)
    b_vec = vector_for(sym2)
    crossing(:lt, a_vec, b_vec).add_constant!(outidx).to_a
  end

  def crossing(method, a, b)
    bitmap = a.send(method, b)
    last_value = bitmap[0]
    bitmap.where do |bflag|
      result = last_value == 1 && bflag == 0
      last_value = bflag
      result
    end
  end

  def find_ones(sym)
    vector_for(sym).where { |e| e == 1 }.add_constant!(outidx).to_a
  end
end


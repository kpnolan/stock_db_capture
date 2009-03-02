require 'rubygems'
require 'gsl'

module ResultAnalysis

  include GSL

  VALID_OPS = [:gt, :lt, :ge, :le, :eq]

  def threshold_crossing(threshold, sym, op)
    raise ArgumentError, "#{op} not one of #{VALID_OPS.join(', ')}" unless VALID_OPS.include? op
    vec = get_vector(sym)
    tvec = GSL::Vector.alloc(vec.len).set_all(threshold)
    bitmap = vec.send(op, tvec)
    bitmap.where { |bflag| bflag == 1 }
  end

  def crosses_over(sym1 ,sym2)
    a_vec = get_vector(sym1)
    b_vec = get_vector(sym2)
    crossing(:gt, a_vec, b_vec)
  end

  def crosses_under(sym1, sym2)
    a_vec = get_vector(sym1)
    b_vec = get_vector(sym2)
    crossing(:lt, a_vec, b_vec)
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
    get_vector(sym).where { |e| e == 1 }
  end
end


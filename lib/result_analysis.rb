require 'rubygems'
require 'narray'

module ResultAnalysis

  VALID_OPS = [:gt, :lt, :ge, :le, :eq]

  def get_vector(sym)
    xa = Array.new(100)
    xa.fill { |i| i* (6*Math::PI/100) }
    x = NArray.to_na(xa)
    if sym == :sin
      NMath.sin(x)
    elsif sym == :cos
      NMath.cos(x)
    else
      raise ArgumentError
    end
  end

  def threshold_crossing(threshold, sym, op)
    raise ArgumentError, "#{op} not one of #{VALID_OPS.join(', ')}" unless VALID_OPS.include? op
    vec = get_vector(sym)
    len = vec.shape.first
    tvec = NArray.float(len).fill!(threshold)
    bitmap = vec.send(op, tvec)
    index = 0
    indexes = []
    bitmap.each do |bflag|
      bflag == 1 && indexes.push(index)
      index += 1
    end
    indexes
  end

  def down_crossing(sym1,sym2)
    na_vec = get_vector(sym1)
    nb_vec = get_vector(sym2)
    crossing(:gt, na_vec, nb_vec)
  end

  def up_crossing(sym1, sym2)
    na_vec = get_vector(sym1)
    nb_vec = get_vector(sym2)
    crossing(:lt, na_vec, nb_vec)
  end

  def crossing(method, a, b)
    index = 0
    indexes = []
    bitmap = a.send(method, b)
    last_value = bitmap[0]
    bitmap.each do |bflag|
      last_value == 1 && bflag == 0 && indexes.push(index)
      index += 1
      last_value = bflag
    end
    indexes
  end
end


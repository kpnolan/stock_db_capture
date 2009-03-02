include GSL

module UserAnalysis
  def zema(options = {})
    options.reverse_merge!(:mlag => 3, :alpha => 0.25, :gain => 1.0)
    idx_range = calc_indexes(nil)
    mlag = options[:mlag]
    alpha = options[:alpha]
    gain = options[:gain]
    raise ArgumentError, "begin time must be equal or more than #{mlag} bars into the timeseries!" if idx_range.begin < mlag
    zema = GSL::Vector.alloc(idx_range.end-idx_range.begin+1)
    today = idx_range.begin - mlag
    prevMA = price[today]
    while today <= idx_range.begin
      prevMA = ((price[today] + gain*(price[today] - price[today-mlag]) - prevMA) * alpha) + prevMA
      today += 1
    end
    zema[0] = prevMA
    outidx = 1
    while today <= idx_range.end
      prevMA = ((price[today] + gain*(price[today] - price[today-mlag]) - prevMA) * alpha) + prevMA
      zema[outidx] = prevMA
      today += 1
      outidx += 1
    end
    result = [0, idx_range.begin, zema]
    memoize_result(self, :zema, idx_range, options, result, :overlap)
    nil
  end
end

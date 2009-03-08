include GSL

module UserAnalysis
  def zema(options = {})
    options.reverse_merge!(:time_period => 3, :gain => 1.0)
    options.reverse_merge! :alpha => 2 / (options[:time_period]+1)
    idx_range = calc_indexes(nil, options[:mlag])
    mlag = options[:mlag]
    alpha = options[:alpha]
    gain = options[:gain]
    raise ArgumentError, "begin time must be equal or more than #{mlag} bars into the timeseries!" if idx_range.begin < mlag
    zema = GSL::Vector.alloc(idx_range.end-idx_range.begin+1)
    today = idx_range.begin - mlag
    prevMA = price[today]
    #FIXME compute a SMA here
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

  def rvi(options={})
    options.reverse_merge! :time_period => 5
    options.reverse_merge! :alpha => (2.0 / (options[:period] + 1))
    idx_range = calc_indexes(nil, options[:time_period])
    out = (rvi_1(high, options) + rvi_1(low, options)).scale(0.5)
    result = [0, idx_range.begin, out]
    memoize_result(self, :rvi, idx_range, options, result, :financebars)
    nil
  end

  def rvi_1(price, options)
    idx_range = calc_indexes(nil, options[:time_period])
    n = options[:period]
    alpha = options[:alpha]
    out = GSL::Vector.alloc(idx_range.end-idx_range.begin+1)
    today = idx_range.begin - n
    upExpAvg = 0.0
    downExpAvg = 0.0
    #
    # compute the SMA for the first output point
    while today <= idx_range.begin
      prev9vec = price.subvector(today-9, 10)
      sd = prev9vec.sd
      if price[today] > price[today-1]
        up, down = sd, 0.0
      else
        down, up = sd, 0.0
      end
      upExpAvg += up
      downExpAvg += down
      today += 1
    end
    upExpAvg /= n
    downExpAvg /= n
    out[0] = 100.0 * (upExpAvg / (upExpAvg+ downExpAvg))
    outidx = 1
    # now we start outputing results
    while today <= idx_range.end
      prev9vec = price.subvector(today-9, 10)
      sd = prev9vec.sd
      if price[today] > price[today-1]
        up, down = sd, 0.0
      else
        down, up = sd, 0.0
      end
      upExpAvg = (up - upExpAvg)*alpha + upExpAvg
      downExpAvg = (down - downExpAvg)*alpha + downExpAvg
      out[outidx] = 100.0 * (upExpAvg / (upExpAvg + downExpAvg))
      today += 1
      outidx += 1
    end
    out
  end
end

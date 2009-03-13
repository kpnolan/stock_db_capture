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
    options.reverse_merge! :alpha => (2.0 / (options[:time_period] + 1))
    idx_range = calc_indexes(nil, options[:time_period])
    out = (rvi_1(high, options) + rvi_1(low, options)).scale(0.5)
    result = [0, idx_range.begin, out]
    memoize_result(self, :rvi, idx_range, options, result, :financebars)
    nil
  end

  def rvi_1(price, options)
    idx_range = calc_indexes(nil, options[:time_period])
    n = options[:time_period]
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

# VALUE1 = ((CLOSE - OPEN) + 2 * (CLOSE (1))*OPEN (1)) + 2*(CLOSE (2)*OPEN (2)) + (CLOSE (3)*OPEN (3))) / 6
# VALUE2 = ((HIGH - LOW) + 2 * (HIGH (1)*LOW (1)) + 2*(HIGH (2)- LOW (2)) + (HIGH (3)*LOW (3))) / 6
# NUM = SUM (VALUE1, N)
# DENUM = SUM (VALUE2, N)
# RVI = NUM / DENUM
# RVISig = (RVI + 2 * RVI (1) + 2 * RVI (2) + RVI (3)) / 6

  def rvig(options={})
    options.reverse_merge! :time_period => 10
    idx_range = calc_indexes(nil, options[:time_period], 6)
    out1 = GSL::Vector.alloc((idx_range.end-idx_range.begin)+1+options[:time_period]+3)
    out2 = GSL::Vector.alloc((idx_range.end-idx_range.begin)+1+options[:time_period]+3)

    t = idx_range.begin - options[:time_period] - 3
    outidx = 0
    while t < idx_range.end
      out1[outidx] = ((close[t]-open[t]) + 2.0*(close[t-1]*open[t-1]) + 2.0*(close[t-2]*open[t-2]) + (close[t-3]*open[t-3]))/6.0
      out2[outidx] = ((high[t]-low[t]) + 2.0*(high[t-1]*low[t-1]) + 2.0*(high[t-2]*low[t-2]) + (high[t-3]*low[t-3]))/6.0
      t += 1
      outidx += 1
    end
    result1 = Talib.ta_sma(options[:time_period], outidx, out1, options[:time_period])
    result2 = Talib.ta_sma(options[:time_period], outidx, out2, options[:time_period])

    num = result1.third
    denom = result2.third
    rvi = num / denom

    rviSig =  GSL::Vector.alloc(rvi.len-3)
    inIdx = 3
    outIdx = 0
    while inIdx < rvi.len
      rviSig[outIdx] = (rvi[inIdx] + 2*rvi[inIdx-1] + 2*rvi[inIdx-2] + rvi[inIdx-3])/6.0
      inIdx += 1
      outIdx += 1
    end
    rlen = rvi.len
    result = [0, idx_range.begin, rvi[3..rlen-1], rviSig]
    memoize_result(self, :rvig, idx_range, options, result, :financebars)
    nil
  end
end

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

include GSL

module UserAnalysis
  def zema(options = {})
    options.reverse_merge!(:time_period => 3, :gain => 1.0, :mlag => 3)
    options.reverse_merge! :alpha => 2.0 / (options[:time_period]+1)
    idx_range = calc_indexes(nil, options[:time_period])
    mlag = options[:mlag]
    alpha = options[:alpha]
    gain = options[:gain]
    raise ArgumentError, "begin time must be equal or more than #{mlag} bars into the timeseries!" if idx_range.begin < mlag
    zema = GSL::Vector.alloc(idx_range.end-idx_range.begin+1)
    today = idx_range.begin - options[:time_period]
    prevMA = price[today..idx_range.begin].mean
    zema[0] = prevMA
    outidx = 1
    today = idx_range.begin+1
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

  # Relative Valatility Index
  def rvi(options={})
    options.reverse_merge! :time_period => 5
    options.reverse_merge! :alpha => (2.0 / (options[:time_period] + 1))
    idx_range = calc_indexes(nil, options[:time_period])
    out = (rvi_1(high, options) + rvi_1(low, options)).scale(0.5)
    result = [0, idx_range.begin, out]
    memoize_result(self, :rvi, idx_range, options, result, :financebars)
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
  # Relative
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
  end

  def linreg(entry_index, options={ })
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(nil, options[:time_period], 0)
    xvec = GSL::Vector.linspace(0, options[:time_period]-1, options[:time_period])
    close_vec = close[entry_index...(entry_index+options[:time_period])]
    ret_vec = GSL::Fit::linear(xvec, close_vec)
    unless options[:noplot]
      out_vec = xvec.to_a.map { |x| x * ret_vec.second + value_at(entry_index, :close)}
      result = [ 0, entry_index, out_vec ]
      memoize_result(self, :linreg, entry_index...(entry_index+options[:time_period]), options, result, :overlap)
    end
    return ret_vec.second
  end

  def lrsigma(options={ })
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(nil, options[:time_period], 0)
    xvec = GSL::Vector.linspace(0, options[:time_period], options[:time_period])
    slopevec = []
    chi = []
    sumvec = []
    today = idx_range.begin - options[:time_period]
    while today < idx_range.end - options[:time_period]
      close_vec = close[today...(today+options[:time_period])]
      ret_vec = GSL::Fit::linear(xvec, close_vec)
      slopevec << ret_vec.second
      sumvec << slopevec.sum
      chi << Math.sqrt(ret_vec[5])
      today += 1
    end
    result = [0, idx_range.begin, sumvec, chi]
    memoize_result(self, :lrsigma, index_range, options, result, :financebars)
  end

  def lr(options={ })
    options.reverse_merge! :time_period => 14
    period = options[:time_period] / 2
    idx_range = calc_indexes(nil, period, 0)
    xvec = GSL::Vector.linspace(0, period*2, period*2)
    slopevec = []
    chisq = []
    today = idx_range.begin - period
    while today < idx_range.end - period +1
      close_vec = close[(today-period)..(today+period)]
      ret_vec = GSL::Fit::linear(xvec, close_vec)
      slopevec << ret_vec.second
      chisq << ret_vec[5]
      today += 1
    end
    result = [0, idx_range.begin, slopevec, chisq]
    memoize_result(self, :lr, index_range, options, result, :financebars)
  end

  def nreturn(options={ })
    idx_range = calc_indexes(nil)
    options.reverse_merge! :basis_index => idx_range.begin
    close_vec = close.to_gv
    len = close_vec.len
    denom = GSL::Vector.linspace(1, len, len)
    entry_price = close[options[:basis_index]]
    outvec = ((close_vec - entry_price)/entry_price)/denom
    result = [0, indx_range.begin, outvect]
    memoize_result(self, :nreturn, index_range, options, result, :financebars)
  end

  def extract(options={})
    raise ArgumentError, "no :slot option given to extract" unless options.has_key? :slot
    idx_range = calc_indexes(nil)
    vec = value_hash[options[:slot]][idx_range]
    result = [0, 0, vec]
    memoize_result(self, :extract, idx_range, options, result, :financebars)
  end

  def calculate(options={})
    raise ArgumentError, "the option :expr must contain a string representing to calculation to perform" if options[:expr].nil? or options[:expr] == ''
    idx_range = calc_indexes(nil)
    expr_string = options[:expr]
    vec = instance_eval(expr_string)
    result = [0, idx_range.begin, vec[idx_range]]
    memoize_result(self, :calculate, idx_range, options, result, :financebars)
  end
end

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'timeseries_exception'

include GSL

class Range
  def lag(p=1)
    (self.begin-1)..(self.end-1)
  end
  def size()
    size = self.end - self.begin
    exclude_end? ? size : size + 1
  end
end

module Enumerable
  def diff
    self[1..-1].zip(self).map {|x| x[0]-x[1]}
  end

  def cumsum
    self.inject([0]){|xs,y| xs.unshift(xs.first + y) }.reverse.slice(1..-1)
  end
end

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

  #Combined macdhist and rocr
  def mhistslope(options={})
    options.reverse_merge!(:signal_period => 9, :time_period => 5)
    idx_range = calc_indexes(:ta_macdfix_lookback, options[:signal_period])
    result = Talib.ta_macdfix(idx_range.begin, idx_range.end, price, options[:signal_period])
    tp = options[:time_period]
    hist_vec = result.last
    len = hist_vec.len
    roc = hist_vec[tp..len-1] / hist_vec[0..len-tp-1]
    ones = GSL::Vector.indgen(roc.len, 1, 0)
    flags = roc.gt(ones).where { |e| e == 1 }
    flags && flags[0]
  end

  #
  # Native Ruby implementation of he RSI
  #
  def rsi1(options={ })
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(:ta_rsi_lookback, options[:time_period])
    today = self.today
    n = options[:time_period]
    n1 = n - 1
    r = options[:rsi]
    emaPos = 0.0
    emaNeg = 0.0
    today += 1
    out = []
    #
    # Now accumulate (and decay) the value of the two ema's solving for
    # the price which would have produced the given RSI without actually
    # writing output points. This "charges up" the ema's so that they have
    # converged prior to the first actual output point
    #
    while today <= idx_range.end
      deltaClose = price[today] - price[today-1]
      up = [0, deltaClose].max
      dn = [0, -deltaClose].max
      emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
      emaNeg = (emaNeg * n1 + dn)/n
      out << 100.0 * (emaPos / (emaPos + emaNeg)) unless today < idx_range.begin
      today += 1
    end
    out
  end

  #
  # return the scalar price, given a series of prices and a time_period (decay rate)
  # that would have produced the given RSI (on the next bar)
  #
  def invrsi(options={ })
    raise ArgumentError, ":rsi must be specified" if options[:rsi].nil?
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(:ta_rsi_lookback, options[:time_period])
    today = self.today
    n = options[:time_period].to_f
    n1 = n - 1.0
    r = options[:rsi]
    emaPos = 0.0
    emaNeg = 0.0
    today += 1
    #
    # compute the SMA for the first the first :time_period bars
    #
    n.to_int.times do
      deltaClose = price[today] - price[today-1]
      up = [0, deltaClose].max
      dn = [0, -deltaClose].max
      emaPos += up
      emaNeg += dn
      today += 1
    end
    emaPos /= n
    emaNeg /= n
    #
    # Now accumulate (and decay) the value of the two ema's solving for
    # the price which would have produced the given RSI
    #
    while today <= idx_range.end
      deltaClose = price[today] - price[today-1]
      up = [0, deltaClose].max
      dn = [0, -deltaClose].max
      emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
      emaNeg = (emaNeg * n1 + dn)/n
      today += 1
    end
    # Now we have to advance the ema (of sort) one more day to get one more decay before we solve
    dn, up = 0.0, 0.0
    #emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
    #emaNeg = (emaNeg * n1 + dn)/n
    # Now solve for up and dn
    posDelta = (100.0*emaPos*n1 - (dn+(emaNeg+emaPos)*n1)*r)/(r-100.0)
    #posDelta = (emaPos*n1*(r-100) + (dn +emaNeg*n1)*r)/(r-100.0)
    negDelta = (-emaPos*n1*(r-100) + emaNeg*(r - n*r)-(r-100)*up)/r #works for downtrend
    last_price = price[today-1]
    last_price+posDelta
  end

  def invrsi_exp(options={ })
    raise ArgumentError, ":rsi must be specified" if options[:rsi].nil?
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(:ta_rsi_lookback, options[:time_period])
    today = self.today
    n = options[:time_period].to_f
    n1 = n - 1.0
    r = options[:rsi]
    emaPos = 0.0
    emaNeg = 0.0
    today += 1
    #
    # compute the SMA for the first the first :time_period bars
    #
    n.to_int.times do
      deltaClose = price[today] - price[today-1]
      up = [0, deltaClose].max
      dn = [0, -deltaClose].max
      emaPos += up
      emaNeg += dn
      today += 1
    end
    emaPos /= n
    emaNeg /= n
    #
    # Now accumulate (and decay) the value of the two ema's solving for
    # the price which would have produced the given RSI
    #
    while today <= idx_range.end
      deltaClose = price[today] - price[today-1]
      up = [0, deltaClose].max
      dn = [0, -deltaClose].max
      emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
      emaNeg = (emaNeg * n1 + dn)/n
      today += 1
    end
    # Now we have to advance the ema (of sort) one more day to get one more decay before we solve
    dn, up = 0.0, 0.0
    emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
    emaNeg = (emaNeg * n1 + dn)/n
    # Now solve for up and dn
    posDelta = (100.0*emaPos*n1 - (dn+(emaNeg+emaPos)*n1)*r)/(r-100.0)
    #posDelta = (emaPos*n1*(r-100) + (dn +emaNeg*n1)*r)/(r-100.0)
    negDelta = (-emaPos*n1*(r-100) + emaNeg*(r - n*r)-(r-100)*up)/r #works for downtrend
    [posDelta, negDelta]
  end

  # Find the linear regression of a TA methods
  def lrmeth(meth, options={})
    options.reverse_merge! :time_period => 14, :maxval => 50.0, :len => 10
    n = options[:len]
    maxval = options[:maxval]
    out_vec = send(meth, :result => :gv)
    len = out_vec.len
    yvec = out_sample = out_vec[0...n]
    max_10 = out_sample.max

    puts "#{meth} #{symbol}\tidx: #{out_sample.to_a.index(max_10)}\t#{max_10}" if max_10 >= maxval
    return index_range.begin+out_sample.to_a.index(max_10) if max_10 >= maxval

    xvec = GSL::Vector.linspace(0, n-1, n)
    retvec = GSL::Fit::linear(xvec, yvec)
    raise Exception, "Non-zero GSL Status: #{retvec.last}" unless retvec.last.zero? || xvec.len != yvec.len

    yval1, yerr1 = GSL::Fit.linear_est(len-1, retvec[0..-1])

    if yval1 >= maxval
      out_sample = out_vec[n...len]
      max_20 = out_sample.max
      if max_20 >= maxval
        puts "#{meth} #{symbol}\tidx: #{out_sample.to_a.index(max_20)+n}\t#{max_20}" if max_10 >= maxval
        return index_range.begin++n+out_sample.to_a.index(max_20)
      else
        puts "#{meth} #{symbol} idx: #{-len}"
        -len
      end
    else
      puts "#{meth} #{symbol} idx: #{-n}"
      -n
    end
  end

  def rsimom(options={})
    options.reverse_merge! :time_period => 14, :maxrsi => 50.0, :len => 10
    rsi_vec = rsi(:result => :array)[0..options[:len]]
    puts "#{symbol} #{local_range.begin.to_formatted_s(:ymd)} rsi_vec: #{rsi_vec.map { |r| (format '%2.2f', r) }.join(' ,')}"
    puts "#{symbol} #{local_range.begin.to_formatted_s(:ymd)} rsi_vec: #{rsi_vec.diff.cumsum.map { |r| (format '%2.2f', r) }.join(' ,')}"

    sum = 0.0
    maxrsi = options[:maxrsi]
    i = 1
    while i < rsi_vec.length
      sum +=  rsi_vec[i] - rsi_vec[i-1]                       # Cumulative Sum of 1st differences
      if sum < 0.0 || rsi_vec[i] >= maxrsi
        puts "#{symbol} #{local_range.begin.to_formatted_s(:ymd)} i: #{i}"
        return(index_range.begin+i)
      end
      i += 1
    end
    puts "#{symbol} #{local_range.begin.to_formatted_s(:ymd)} i: NOT FOUND"
    puts ""
  end

   # Relative Valatility Index
  def rvi(options={})
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(:ta_rvi_lookback, options[:time_period])
    raise TimeseriesException, "#{symbol}: length(#{high.len}) < range.end(#{idx_range.end})" if high.len < idx_range.end

    options = options.merge :idx_range => idx_range
    out = ( rvi_wilder(high, options) + rvi_wilder(low, options)).scale(0.5)
    result = [0, idx_range.begin, out]
    memoize_result(self, :rvi, idx_range, options, result, :financebars)
  end

  def rvi_wilder(price, options)
    idx_range, n = options[:idx_range], options[:time_period].to_f
    today = self.today
    outidx = 0
    n1 = n - 1.0
    out_len = idx_range.end-idx_range.begin+1
    out_len = 1 if out_len.zero?
    out = GSL::Vector.alloc(out_len)
    emaPos = 0.0
    emaNeg = 0.0
    #
    # compute the SMA for the first output point
    today += 9
    n.to_int.times do
      prev10vec = price.subvector(today-9, 9)
      sd = prev10vec.sd
      if price[today] > price[today-1]
        up, dn = sd, 0.0
      else
        dn, up = sd, 0.0
      end
      emaPos += up
      emaNeg += dn
      today += 1
    end
    today -= 9
    emaPos /= n
    emaNeg /= n
    out[0] = 100.0 * (emaPos / (emaPos+ emaNeg))
    today += 1
    outidx += 1

    begin
      while today <= idx_range.end
        prev9vec = price.subvector(today-9, 9)
        sd = prev9vec.sd
        if price[today] > price[today-1]
          up, dn = sd, 0.0
        else
          dn, up = sd, 0.0
        end
        emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
        emaNeg = (emaNeg * n1 + dn)/n
        if today > idx_range.begin        # start outputing points once were past the preamble
          out[outidx] = 100.0 * (emaPos / (emaPos + emaNeg))
          outidx += 1
        end
        today += 1
      end
    rescue Exception => e
      puts "today: #{today} price.len: #{price.len} idx_range.end: #{idx_range.end} out.len: #{out.len}"
      raise
    end
    out
  end

  # Arms Ease of Movement
  def arms_eom()
    range = calc_indexes(nil, 1)
    outvec = ((high[range]+low[range])/2 - (high[range.lag]-low[range.lag]/2)) / (volume[range]/(high[range]-low[range]))
    result = [0, outidx, outvec]
    memoize_result(self, :arms_eom, range, options, result, :overlap)
  end

  # Price Volume Trend
  def pvt()
    range = calc_indexes(nil, 1)

    subtotal = volume[range]*(close[range] - close[range.lag])/close[range.lag]
    outvec = subtotal.cumsum()
    result = [0, outidx, outvec]
    memoize_result(self, :pvt, range, options, result, :overlap)
  end

  # Relative Valatility Index
  def invrvi(options={})
    options.reverse_merge! :time_period => 14
    idx_range = calc_indexes(:ta_rsi_lookback, options[:time_period])
    raise TimeseriesException, "#{symbol}: length(#{high.len}) < range.end(#{idx_range.end})" if high.len < idx_range.end

    options = options.merge :idx_range => idx_range
    low_price = invrvi_wilder(low, options)
    high_price = invrvi_wilder(high, options)
    (low_price + high_price) / 2.0
  end

  def invrvi_wilder(price, options)
    idx_range, n = options[:idx_range], options[:time_period].to_f
    today = self.today
    n1 = n - 1.0
    r = options[:rvi]
    emaPos = 0.0
    emaNeg = 0.0
    #
    # compute the SMA for the first output point
    today += 9
    n.to_int.times do
      prev10vec = price.subvector(today-9, 9)
      sd = prev10vec.sd
      if price[today] > price[today-1]
        up, dn = sd, 0.0
      else
        dn, up = sd, 0.0
      end
      emaPos += up
      emaNeg += dn
      today += 1
    end
    today -= 9
    emaPos /= n
    emaNeg /= n
    today += 1

    begin
      while today <= idx_range.end
        prev9vec = price.subvector(today-9, 9)
        sd = prev9vec.sd
        if price[today] > price[today-1]
          up, dn = sd, 0.0
        else
          dn, up = sd, 0.0
        end
        emaPos = (emaPos * n1 + up)/n     # add the current price to the decayed sum
        emaNeg = (emaNeg * n1 + dn)/n
        today += 1
      end
    rescue Exception => e
      puts "#{e.to_s} -- today: #{today} price.len: #{price.len} idx_range.end: #{idx_range.end}"
      raise
    end
    dn = 0.0
    delta = (100*emaPos*n1 - (dn+(emaNeg+emaPos)*n1)*r)/(r-100)
    price[today-1]+delta
  end

  # VALUE1 = ((CLOSE - OPEN) + 2 * (CLOSE (1))*OPEN (1)) + 2*(CLOSE (2)*OPEN (2)) + (CLOSE (3)*OPEN (3))) / 6
  # VALUE2 = ((HIGH - LOW) + 2 * (HIGH (1)*LOW (1)) + 2*(HIGH (2)- LOW (2)) + (HIGH (3)*LOW (3))) / 6
  # NUM = SUM (VALUE1, N)
  # DENUM = SUM (VALUE2, N)
  # RVI = NUM / DENUM
  # RVISig = (RVI + 2 * RVI (1) + 2 * RVI (2) + RVI (3)) / 6
  # Relative Vigor Index
  def rvig(options={})
    options.reverse_merge! :time_period => 5
    idx_range = calc_indexes(:ta_sma_lookback, options[:time_period]+18)
    nan = 0.0/0.0

    work = close.dup
    close1 = work.unshift(nan)[0..-2]
    close2 = work.unshift(nan)[0..-3]
    close3 = work.unshift(nan)[0..-4]

    work = opening.dup
    open = opening
    open1 = work.unshift(nan)[0..-2]
    open2 = work.unshift(nan)[0..-3]
    open3 = work.unshift(nan)[0..-4]


    work = high.dup
    high1 = work.unshift(nan)[0..-2]
    high2 = work.unshift(nan)[0..-3]
    high3 = work.unshift(nan)[0..-4]

    work = low.dup
    low1 = work.unshift(nan)[0..-2]
    low2 = work.unshift(nan)[0..-3]
    low3 = work.unshift(nan)[0..-4]

    out1 = (close-open + (close1-open1).scale(2.0) + (close2-open2).scale(2.0) + (close3-open3)).scale(1.0/6.0)#[3..-1]
    out2 = (high-low + (high1-low1).scale(2.0) + (high2-low2).scale(2.0) + (high3-low3)).scale(1.0/6.0)#[3..-1]

    result1 = Talib.ta_sma(idx_range.begin-6, idx_range.end, out1, options[:time_period])
    result2 = Talib.ta_sma(idx_range.begin-6, idx_range.end, out2, options[:time_period])

    num = result1.third
    denom = result2.third
    rvi = (num / denom).scale(100.0)

    work = rvi.dup
    rvi1 = work.unshift(nan)[0..-2]
    rvi2 = work.unshift(nan)[0..-3]
    rvi3 = work.unshift(nan)[0..-4]
    rviSig = (rvi + 2.0*rvi1 + 2.0*rvi2 + rvi3)/6.0

    result = [0, outidx, rvi[6..-1], rviSig[6..-1]]
    memoize_result(self, :rvig, idx_range, options, result, :financebars)
  end

  def linreg(options={ })
    options.reverse_merge! :time_period => 7
    n = options[:time_period]
    idx_range = calc_indexes(nil)
    entry_index = idx_range.begin
    price = options[:price]
    xvec = GSL::Vector.linspace(0, n-1, n)
    price_vec = (high[entry_index...(entry_index+n)]+low[entry_index...(entry_index+n)]).scale(0.5)
    ret_vec = GSL::Fit::linear(xvec, price_vec)
    if options[:plot_results]
      out_vec = xvec.to_a.map { |x| x * ret_vec.second + value_at(entry_index, price)}
      result = [ 0, entry_index, out_vec ]
      memoize_result(self, :linreg, entry_index...(entry_index+n), options, result, :overlap)
    else
      out_vec = GSL::Vector.alloc(n)
      out_vec[-1] = ret_vec.second
      result = [ 0, entry_index, out_vec ]
      if ret_vec.second < 0.0
        puts out_vec.to_a.join(', ')
      end
      memoize_result(self, :linreg, entry_index...(entry_index+n), options, result, :overlap)
    end
  end

  def lrclose(options={ })
    options.reverse_merge! :time_period => 10
    idx_range = calc_indexes(nil, options[:time_period])
    n = options[:time_period]
    xvec = GSL::Vector.linspace(1, n, n)
    yvec = close.subvector(self.today, n)
    retvec = GSL::Fit::linear(xvec, yvec)
    corr = Stats.correlation(xvec, yvec)
    raise Exception, "RBGSL Exception" unless retvec.last.zero?
    [retvec[1], corr]
  end

  def lrclose0(options={ })
    options.reverse_merge! :time_period => 10
    idx_range = calc_indexes(nil, 0)
    n = options[:time_period]
    xvec = GSL::Vector.linspace(1, n, n)
    yvec = close.subvector(self.today, n)
    retvec = GSL::Fit::linear(xvec, yvec)
    corr = Stats.correlation(xvec, yvec).abs
    raise Exception, "RBGSL Exception" unless retvec.last.zero?
    [retvec.second, corr]
  end

  def mom_percent(options={ })
    options.reverse_merge! :time_period => 0, :grace_period => 7, :absolute => true
    n = options[:time_period]
    grace = options[:grace_period]
    index_ranage = calc_indexes(nil, options[:time_period])
    out = GSL::Vector.alloc(index_range.end-index_range.begin+1)
    entry_price = price[index_range.begin]
    for i in index_range
      days_held = i - index_range.begin
      if days_held > grace
        ratio = options[:absolute] ? (price[i]-entry_price)/entry_price : (price[i]-price[i-n])/price[i]
      else
        ratio = 0.0
      end
      out[days_held] = ratio
    end
    result = [ 0, index_range.begin, out ]
    memoize_result(self, :mom_percent, index_range, options, result, :financebars)
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

  def anchored_mom(options={})
    idx_range = calc_indexes(nil,0)
    momvec = []
    today = idx_range.begin
    reference_close = close[idx_range.begin]
    while today < idx_range.end
      momvec << (close[today] - reference_close)
      today += 1
    end
    result = [0, idx_range.begin, momvec.to_gv]
    memoize_result(self, :anchored_mom, index_range, options, result, :financebars)
  end

  def slope(options={ })
    options.reverse_merge! :time_period => 5
    n = options[:time_period]
    idx_range = calc_indexes(nil)
    entry_index = idx_range.begin
    price = options[:price]
    price_vec = send(price)[entry_index...(entry_index+n)]
    xvec = GSL::Vector.linspace(0, n-1, n)
    ret_vec = GSL::Fit::linear(xvec, price_vec)
    out_vec = xvec.to_a.map { |x| x * ret_vec.second + value_at(entry_index, :close)}
    result = [ 0, entry_index, out_vec ]
    memoize_result(self, :linreg, entry_index...(entry_index+n), options, result, :overlap)
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

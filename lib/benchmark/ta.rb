#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
module Ta
  #
  # Native Ruby implementation of he RSI
  #
  def rsi2(price, idx_range, options={ })
    options = { :time_period => 14 }.merge(options)
    today = 1
    n = options[:time_period]
    n1 = n - 1
    emaPos = 0.0
    emaNeg = 0.0
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
end

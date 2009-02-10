include GSL

module UserAnalysis
  def linear_regression(time_range, yVec = close, options={})
    idx_range = calc_indexes(nil, time_range)
    sample_count = idx_range.end - idx_range.begin + 1
    xvec = GSL::Vector.linspace(0, sample_count-1, sample_count)
    yvec = yVec[idx_range]
    yinter, slope = GSL::Fit::linear(xvec, yvec)
    outVec = GSL::Vector.linspace(yinter, slope*sample_count+yinter, sample_count)
    result = [0, idx_range.begin, outVec]
    memoize_result(self, :linear_regression, time_range, idx_range, options, result, :overlap)
  end

  def detrend(time_range, yVec = close, options={})
    if (pb = find_memo(:linear_regression, time_range))
      idx_range, vecs = pb.decode(:index_range, :vectors)
    else
      pb = linear_regression(time_range, yVec)
      idx_range, vecs = pb.decode(:index_range, :vectors)
    end
    dt_close = yVec[idx_range] - vecs.first
    result = [0, idx_range.begin, dt_close]
    memoize_result(self, :detrend, time_range, idx_range, options, result, :overlap)
  end

  def detrended_stddev(time_range, yVec = close, options={})
    options.reverse_merge!(:time_period => 5, :deviations => 1.0)
    if (pb = find_memo(:detrend, time_range))
      idx_range, vecs = pb.decode(:index_range, :vectors)
    else
      pb = detrend(time_range, yVec)
      idx_range, vecs = pb.decode(:index_range, :vectors)
    end
    sample_count = idx_range.end - idx_range.begin + 1
    result  = Talib.ta_stddev(0, sample_count-1, vecs.first, options[:time_period], options[:deviations])
    memoize_result(self, :detrended_stddev, time_range, idx_range, options, result)
  end
end

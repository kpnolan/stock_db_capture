module ClassMethods
  def talib_init
    if @unstable_fcn_map.nil?
      @unstable_fcn_map = {}
      UNSTABLE_PERIOD_METHODS.each_with_index { |meth, i| @unstable_fcn_map[meth] = i }
      @unstable_fcn_map[:rvi] = @unstable_fcn_map[:rsi]
    end
  end

  def set_unstable_period(meth, value)
    raise ArgumentError, "bad method for unstable period: #{meth}" if @unstable_fcn_map[meth].nil?
    Talib.ta_set_unstable_period(@unstable_fcn_map[meth], value)
  end

  def get_unstable_period(meth)
    raise ArgumentError, "bad method for unstable period: #{meth}" if @unstable_fcn_map[meth].nil?
    Talib.ta_get_unstable_period(@unstable_fcn_map[meth])
  end

  def base_indicator(lookback_fcn)
    bi = nil
    bi = lookback_fcn.to_s[/^ta_(\w+)_lookback$/,1] if lookback_fcn
    bi.nil? ? bi : bi.to_sym
  end
  #
  # Retuns the minimal number of samples a TA function needs. The value will be then used
  # to check if we have buffered enough samples before the begining of the real data so that
  # we get a full vector of results
  #
  def minimal_samples(lookback_fcn, *args)
    ms = lookback_fcn ? Talib.send(lookback_fcn, *args) : args.sum
  end

  def to_lookback(sym)
    "ta_#{sym.to_s}_lookback".to_sym
  end

  def optimize_prefetch(method_hash)
    method_hash.sort do |a,b|
      a_pre = prefetch_bars(a.first, *TALIB_META_INFO_DICTIONARY[a.first].form_param_list(a.last))
      b_pre = prefetch_bars(b.first, *TALIB_META_INFO_DICTIONARY[b.first].form_param_list(b.last))
      b_pre > a_pre ? 1 : b_pre < a_pre ? -1 : 0
    end
  end

  def prefetch_bars(short_form, *args)
    indicator_prefetch(short_form, *args)
  end

  def indicator_prefetch(base_indicator, *args)
    case base_indicator
    when :ema then
      unstable = (3.45*(args[0]+1)).ceil
      set_unstable_period(:ema, count)
      minimal_samples(to_lookback(base_indicator), *args)
    when :rsi then
      unstable = (2.0*(args[0]+1)).ceil
      unstable = 50
      set_unstable_period(:rsi, unstable)
      ms = minimal_samples(to_lookback(:rsi), *args)
      ms
    when :mfi then
      unstable = 50
      set_unstable_period(:mfi, unstable)
      unstable + args.sum
    when :rvi then
      unstable = (2.0*(args[0]+1+9)).ceil
      unstable = 50
      set_unstable_period(:rsi, unstable)
      ms = minimal_samples(to_lookback(:rsi), *args)
    when :macd, :macdfix then
      ratio = 1.75
      unstable = (ratio*26+1).ceil
      set_unstable_period(:ema, unstable)
      minimal_samples(to_lookback(base_indicator), *args)
    when :macdext then
      ratio = 1.75
      unstable = (ratio*13+1).ceil
      set_unstable_period(:ema, unstable)
      minimal_samples(to_lookback(base_indicator), *args)
    when :mom then
      minimal_samples(to_lookback(:mom), *args)
    else
      minimal_samples(to_lookback(base_indicator), *args)
    end
  end
end

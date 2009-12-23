# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

    ###############################################################################################################
    # DON'T EDIT THIS FILE !!!
    # This file was automatically generated from 'ta_func.xml'
    # If, for some reason the interface to Talib changes, but the Swig I/F file 'ta_func.swg' must change as well
    # as 'ta_func.xml'. This file contains the "shadow methods" that the writers of the SWIG I/F deemed unneccessary.
    # I think the Swig interface is still to low-level and created this higher-level interface that really is designed
    # to be a mixin to the Timeseries class upon with talib functions operate.
    ################################################################################################################
module TechnicalAnalysis

  UNSTABLE_PERIOD_METHODS = [ :adx, :adxr, :atr, :cmo, :dx, :ema, :ht_dcperiod, :ht_dcphace, :ht_phasor, :ht_sine,
                             :ht_trendline, :ht_trendmode, :kama, :mama, :mfi, :minus_di, :minus_dm, :natr, :plus_di, :plus_dm,
                             :rsi, :stoch_rsi, :t3, :all ]

  def self.included(base)
    base.extend(ClassMethods)
    base.talib_init()
  end

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
        set_unstable_period(:rsi, unstable)
        ms = minimal_samples(to_lookback(:rsi), *args)
        ms
      when :rvi then
        unstable = (2.0*(args[0]+1+9)).ceil
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
        minimal_samples(to_lookback(base_indicator), *args)
      else
        raise TimeseriesException, "unknown lookback function -- :#{base_indicator}"
      end
    end
  end

  #Vector Trigonometric ACos
  def acos(inReal, options={})
    idx_range = calc_indexes(:ta_acos_lookback)
    result = Talib.ta_acos(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :acos, idx_range, options, result)
  end

  #Chaikin A/D Line
  def ad(options={})
    idx_range = calc_indexes(:ta_ad_lookback)
    result = Talib.ta_ad(idx_range.begin, idx_range.end, high, low, close, volume)
    memoize_result(self, :ad, idx_range, options, result)
  end

  #Vector Arithmetic Add
  def add(inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_add_lookback)
    result = Talib.ta_add(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(self, :add, idx_range, options, result)
  end

  #Chaikin A/D Oscillator
  def adosc(options={})
    options.reverse_merge!(:fast_period => 3, :slow_period => 10)
    idx_range = calc_indexes(:ta_adosc_lookback, options[:fast_period], options[:slow_period])
    result = Talib.ta_adosc(idx_range.begin, idx_range.end, high, low, close, volume, options[:fast_period], options[:slow_period])
    memoize_result(self, :adosc, idx_range, options, result)
  end

  #Average Directional Movement Index
  def adx(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_adx_lookback, options[:time_period])
    result = Talib.ta_adx(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :adx, idx_range, options, result, :financebars)
  end

  #Average Directional Movement Index Rating
  def adxr(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_adxr_lookback, options[:time_period])
    result = Talib.ta_adxr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :adxr, idx_range, options, result, :financebars)
  end

  #Absolute Price Oscillator
  def apo(options={})
    options.reverse_merge!(:fast_period => 12, :slow_period => 26, :ma_type => 0)
    idx_range = calc_indexes(:ta_apo_lookback, options[:fast_period], options[:slow_period], options[:ma_type])
    result = Talib.ta_apo(idx_range.begin, idx_range.end, price, options[:fast_period], options[:slow_period], options[:ma_type])
    memoize_result(self, :apo, idx_range, options, result)
  end

  #Aroon
  def aroon(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_aroon_lookback, options[:time_period])
    result = Talib.ta_aroon(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(self, :aroon, idx_range, options, result)
  end

  #Aroon Oscillator
  def aroonosc(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_aroonosc_lookback, options[:time_period])
    result = Talib.ta_aroonosc(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(self, :aroonosc, idx_range, options, result)
  end

  #Vector Trigonometric ASin
  def asin(inReal, options={})
    idx_range = calc_indexes(:ta_asin_lookback)
    result = Talib.ta_asin(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :asin, idx_range, options, result)
  end

  #Vector Trigonometric ATan
  def atan(inReal, options={})
    idx_range = calc_indexes(:ta_atan_lookback)
    result = Talib.ta_atan(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :atan, idx_range, options, result)
  end

  #Average True Range
  def atr(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_atr_lookback, options[:time_period])
    result = Talib.ta_atr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :atr, idx_range, options, result, :unstable_period)
  end

  #Average Price
  def avgprice(options={})
    idx_range = calc_indexes(:ta_avgprice_lookback)
    result = Talib.ta_avgprice(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :avgprice, idx_range, options, result, :overlap)
  end

  #Bollinger Bands
  def bbands(options={})
    options.reverse_merge!(:time_period => 5, :deviations_up => 2.0, :deviations_down => 2.0, :ma_type => 0)
    idx_range = calc_indexes(:ta_bbands_lookback, options[:time_period], options[:deviations_up], options[:deviations_down], options[:ma_type])
    result = Talib.ta_bbands(idx_range.begin, idx_range.end, price, options[:time_period], options[:deviations_up], options[:deviations_down], options[:ma_type])
    memoize_result(self, :bbands, idx_range, options, result, :overlap)
  end

  #Beta
  def beta(inReal0, inReal1, options={})
    options.reverse_merge!(:time_period => 5)
    idx_range = calc_indexes(:ta_beta_lookback, options[:time_period])
    result = Talib.ta_beta(idx_range.begin, idx_range.end, inReal0, inReal1, options[:time_period])
    memoize_result(self, :beta, idx_range, options, result)
  end

  #Balance Of Power
  def bop(options={})
    idx_range = calc_indexes(:ta_bop_lookback)
    result = Talib.ta_bop(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :bop, idx_range, options, result)
  end

  #Commodity Channel Index
  def cci(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_cci_lookback, options[:time_period])
    result = Talib.ta_cci(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :cci, idx_range, options, result)
  end

  #Two Crows
  def cdl2crows(options={})
    idx_range = calc_indexes(:ta_cdl_2crows_lookback)
    result = Talib.ta_cdl_2crows(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl2crows, idx_range, options, result, :candlestick)
  end

  #Three Black Crows
  def cdl3blackcrows(options={})
    idx_range = calc_indexes(:ta_cdl_3blackcrows_lookback)
    result = Talib.ta_cdl_3blackcrows(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl3blackcrows, idx_range, options, result, :candlestick)
  end

  #Three Inside Up/Down
  def cdl3inside(options={})
    idx_range = calc_indexes(:ta_cdl_3inside_lookback)
    result = Talib.ta_cdl_3inside(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl3inside, idx_range, options, result, :candlestick)
  end

  #Three-Line Strike
  def cdl3linestrike(options={})
    idx_range = calc_indexes(:ta_cdl_3linestrike_lookback)
    result = Talib.ta_cdl_3linestrike(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl3linestrike, idx_range, options, result, :candlestick)
  end

  #Three Outside Up/Down
  def cdl3outside(options={})
    idx_range = calc_indexes(:ta_cdl_3outside_lookback)
    result = Talib.ta_cdl_3outside(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl3outside, idx_range, options, result, :candlestick)
  end

  #Three Stars In The South
  def cdl3starsinsouth(options={})
    idx_range = calc_indexes(:ta_cdl_3starsinsouth_lookback)
    result = Talib.ta_cdl_3starsinsouth(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl3starsinsouth, idx_range, options, result, :candlestick)
  end

  #Three Advancing White Soldiers
  def cdl3whitesoldiers(options={})
    idx_range = calc_indexes(:ta_cdl_3whitesoldiers_lookback)
    result = Talib.ta_cdl_3whitesoldiers(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdl3whitesoldiers, idx_range, options, result, :candlestick)
  end

  #Abandoned Baby
  def cdlabandonedbaby(options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdlabandonedbaby_lookback, options[:penetration])
    result = Talib.ta_cdlabandonedbaby(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdlabandonedbaby, idx_range, options, result, :candlestick)
  end

  #Advance Block
  def cdladvanceblock(options={})
    idx_range = calc_indexes(:ta_cdladvanceblock_lookback)
    result = Talib.ta_cdladvanceblock(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdladvanceblock, idx_range, options, result, :candlestick)
  end

  #Belt-hold
  def cdlbelthold(options={})
    idx_range = calc_indexes(:ta_cdlbelthold_lookback)
    result = Talib.ta_cdlbelthold(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlbelthold, idx_range, options, result, :candlestick)
  end

  #Breakaway
  def cdlbreakaway(options={})
    idx_range = calc_indexes(:ta_cdlbreakaway_lookback)
    result = Talib.ta_cdlbreakaway(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlbreakaway, idx_range, options, result, :candlestick)
  end

  #Closing Marubozu
  def cdlclosingmarubozu(options={})
    idx_range = calc_indexes(:ta_cdlclosingmarubozu_lookback)
    result = Talib.ta_cdlclosingmarubozu(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlclosingmarubozu, idx_range, options, result, :candlestick)
  end

  #Concealing Baby Swallow
  def cdlconcealbabyswall(options={})
    idx_range = calc_indexes(:ta_cdlconcealbabyswall_lookback)
    result = Talib.ta_cdlconcealbabyswall(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlconcealbabyswall, idx_range, options, result, :candlestick)
  end

  #Counterattack
  def cdlcounterattack(options={})
    idx_range = calc_indexes(:ta_cdlcounterattack_lookback)
    result = Talib.ta_cdlcounterattack(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlcounterattack, idx_range, options, result, :candlestick)
  end

  #Dark Cloud Cover
  def cdldarkcloudcover(options={})
    options.reverse_merge!(:penetration => 0.5)
    idx_range = calc_indexes(:ta_cdldarkcloudcover_lookback, options[:penetration])
    result = Talib.ta_cdldarkcloudcover(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdldarkcloudcover, idx_range, options, result, :candlestick)
  end

  #Doji
  def cdldoji(options={})
    idx_range = calc_indexes(:ta_cdldoji_lookback)
    result = Talib.ta_cdldoji(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdldoji, idx_range, options, result, :candlestick)
  end

  #Doji Star
  def cdldojistar(options={})
    idx_range = calc_indexes(:ta_cdldojistar_lookback)
    result = Talib.ta_cdldojistar(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdldojistar, idx_range, options, result, :candlestick)
  end

  #Dragonfly Doji
  def cdldragonflydoji(options={})
    idx_range = calc_indexes(:ta_cdldragonflydoji_lookback)
    result = Talib.ta_cdldragonflydoji(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdldragonflydoji, idx_range, options, result, :candlestick)
  end

  #Engulfing Pattern
  def cdlengulfing(options={})
    idx_range = calc_indexes(:ta_cdlengulfing_lookback)
    result = Talib.ta_cdlengulfing(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlengulfing, idx_range, options, result, :candlestick)
  end

  #Evening Doji Star
  def cdleveningdojistar(options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdleveningdojistar_lookback, options[:penetration])
    result = Talib.ta_cdleveningdojistar(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdleveningdojistar, idx_range, options, result, :candlestick)
  end

  #Evening Star
  def cdleveningstar(options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdleveningstar_lookback, options[:penetration])
    result = Talib.ta_cdleveningstar(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdleveningstar, idx_range, options, result, :candlestick)
  end

  #Up/Down-gap side-by-side white lines
  def cdlgapsidesidewhite(options={})
    idx_range = calc_indexes(:ta_cdlgapsidesidewhite_lookback)
    result = Talib.ta_cdlgapsidesidewhite(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlgapsidesidewhite, idx_range, options, result, :candlestick)
  end

  #Gravestone Doji
  def cdlgravestonedoji(options={})
    idx_range = calc_indexes(:ta_cdlgravestonedoji_lookback)
    result = Talib.ta_cdlgravestonedoji(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlgravestonedoji, idx_range, options, result, :candlestick)
  end

  #Hammer
  def cdlhammer(options={})
    idx_range = calc_indexes(:ta_cdlhammer_lookback)
    result = Talib.ta_cdlhammer(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlhammer, idx_range, options, result, :candlestick)
  end

  #Hanging Man
  def cdlhangingman(options={})
    idx_range = calc_indexes(:ta_cdlhangingman_lookback)
    result = Talib.ta_cdlhangingman(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlhangingman, idx_range, options, result, :candlestick)
  end

  #Harami Pattern
  def cdlharami(options={})
    idx_range = calc_indexes(:ta_cdlharami_lookback)
    result = Talib.ta_cdlharami(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlharami, idx_range, options, result, :candlestick)
  end

  #Harami Cross Pattern
  def cdlharamicross(options={})
    idx_range = calc_indexes(:ta_cdlharamicross_lookback)
    result = Talib.ta_cdlharamicross(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlharamicross, idx_range, options, result, :candlestick)
  end

  #High-Wave Candle
  def cdlhighwave(options={})
    idx_range = calc_indexes(:ta_cdlhighwave_lookback)
    result = Talib.ta_cdlhighwave(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlhighwave, idx_range, options, result, :candlestick)
  end

  #Hikkake Pattern
  def cdlhikkake(options={})
    idx_range = calc_indexes(:ta_cdlhikkake_lookback)
    result = Talib.ta_cdlhikkake(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlhikkake, idx_range, options, result, :candlestick)
  end

  #Modified Hikkake Pattern
  def cdlhikkakemod(options={})
    idx_range = calc_indexes(:ta_cdlhikkakemod_lookback)
    result = Talib.ta_cdlhikkakemod(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlhikkakemod, idx_range, options, result, :candlestick)
  end

  #Homing Pigeon
  def cdlhomingpigeon(options={})
    idx_range = calc_indexes(:ta_cdlhomingpigeon_lookback)
    result = Talib.ta_cdlhomingpigeon(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlhomingpigeon, idx_range, options, result, :candlestick)
  end

  #Identical Three Crows
  def cdlidentical3crows(options={})
    idx_range = calc_indexes(:ta_cdlidentical3crows_lookback)
    result = Talib.ta_cdlidentical3crows(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlidentical3crows, idx_range, options, result, :candlestick)
  end

  #In-Neck Pattern
  def cdlinneck(options={})
    idx_range = calc_indexes(:ta_cdlinneck_lookback)
    result = Talib.ta_cdlinneck(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlinneck, idx_range, options, result, :candlestick)
  end

  #Inverted Hammer
  def cdlinvertedhammer(options={})
    idx_range = calc_indexes(:ta_cdlinvertedhammer_lookback)
    result = Talib.ta_cdlinvertedhammer(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlinvertedhammer, idx_range, options, result, :candlestick)
  end

  #Kicking
  def cdlkicking(options={})
    idx_range = calc_indexes(:ta_cdlkicking_lookback)
    result = Talib.ta_cdlkicking(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlkicking, idx_range, options, result, :candlestick)
  end

  #Kicking - bull/bear determined by the longer marubozu
  def cdlkickingbylength(options={})
    idx_range = calc_indexes(:ta_cdlkickingbylength_lookback)
    result = Talib.ta_cdlkickingbylength(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlkickingbylength, idx_range, options, result, :candlestick)
  end

  #Ladder Bottom
  def cdlladderbottom(options={})
    idx_range = calc_indexes(:ta_cdlladderbottom_lookback)
    result = Talib.ta_cdlladderbottom(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlladderbottom, idx_range, options, result, :candlestick)
  end

  #Long Legged Doji
  def cdllongleggeddoji(options={})
    idx_range = calc_indexes(:ta_cdllongleggeddoji_lookback)
    result = Talib.ta_cdllongleggeddoji(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdllongleggeddoji, idx_range, options, result, :candlestick)
  end

  #Long Line Candle
  def cdllongline(options={})
    idx_range = calc_indexes(:ta_cdllongline_lookback)
    result = Talib.ta_cdllongline(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdllongline, idx_range, options, result, :candlestick)
  end

  #Marubozu
  def cdlmarubozu(options={})
    idx_range = calc_indexes(:ta_cdlmarubozu_lookback)
    result = Talib.ta_cdlmarubozu(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlmarubozu, idx_range, options, result, :candlestick)
  end

  #Matching Low
  def cdlmatchinglow(options={})
    idx_range = calc_indexes(:ta_cdlmatchinglow_lookback)
    result = Talib.ta_cdlmatchinglow(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlmatchinglow, idx_range, options, result, :candlestick)
  end

  #Mat Hold
  def cdlmathold(options={})
    options.reverse_merge!(:penetration => 0.5)
    idx_range = calc_indexes(:ta_cdlmathold_lookback, options[:penetration])
    result = Talib.ta_cdlmathold(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdlmathold, idx_range, options, result, :candlestick)
  end

  #Morning Doji Star
  def cdlmorningdojistar(options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdlmorningdojistar_lookback, options[:penetration])
    result = Talib.ta_cdlmorningdojistar(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdlmorningdojistar, idx_range, options, result, :candlestick)
  end

  #Morning Star
  def cdlmorningstar(options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdlmorningstar_lookback, options[:penetration])
    result = Talib.ta_cdlmorningstar(idx_range.begin, idx_range.end, opening, high, low, close, options[:penetration])
    memoize_result(self, :cdlmorningstar, idx_range, options, result, :candlestick)
  end

  #On-Neck Pattern
  def cdlonneck(options={})
    idx_range = calc_indexes(:ta_cdlonneck_lookback)
    result = Talib.ta_cdlonneck(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlonneck, idx_range, options, result, :candlestick)
  end

  #Piercing Pattern
  def cdlpiercing(options={})
    idx_range = calc_indexes(:ta_cdlpiercing_lookback)
    result = Talib.ta_cdlpiercing(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlpiercing, idx_range, options, result, :candlestick)
  end

  #Rickshaw Man
  def cdlrickshawman(options={})
    idx_range = calc_indexes(:ta_cdlrickshawman_lookback)
    result = Talib.ta_cdlrickshawman(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlrickshawman, idx_range, options, result, :candlestick)
  end

  #Rising/Falling Three Methods
  def cdlrisefall3methods(options={})
    idx_range = calc_indexes(:ta_cdlrisefall3methods_lookback)
    result = Talib.ta_cdlrisefall3methods(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlrisefall3methods, idx_range, options, result, :candlestick)
  end

  #Separating Lines
  def cdlseparatinglines(options={})
    idx_range = calc_indexes(:ta_cdlseparatinglines_lookback)
    result = Talib.ta_cdlseparatinglines(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlseparatinglines, idx_range, options, result, :candlestick)
  end

  #Shooting Star
  def cdlshootingstar(options={})
    idx_range = calc_indexes(:ta_cdlshootingstar_lookback)
    result = Talib.ta_cdlshootingstar(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlshootingstar, idx_range, options, result, :candlestick)
  end

  #Short Line Candle
  def cdlshortline(options={})
    idx_range = calc_indexes(:ta_cdlshortline_lookback)
    result = Talib.ta_cdlshortline(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlshortline, idx_range, options, result, :candlestick)
  end

  #Spinning Top
  def cdlspinningtop(options={})
    idx_range = calc_indexes(:ta_cdlspinningtop_lookback)
    result = Talib.ta_cdlspinningtop(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlspinningtop, idx_range, options, result, :candlestick)
  end

  #Stalled Pattern
  def cdlstalledpattern(options={})
    idx_range = calc_indexes(:ta_cdlstalledpattern_lookback)
    result = Talib.ta_cdlstalledpattern(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlstalledpattern, idx_range, options, result, :candlestick)
  end

  #Stick Sandwich
  def cdlsticksandwich(options={})
    idx_range = calc_indexes(:ta_cdlsticksandwich_lookback)
    result = Talib.ta_cdlsticksandwich(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlsticksandwich, idx_range, options, result, :candlestick)
  end

  #Takuri (Dragonfly Doji with very long lower shadow)
  def cdltakuri(options={})
    idx_range = calc_indexes(:ta_cdltakuri_lookback)
    result = Talib.ta_cdltakuri(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdltakuri, idx_range, options, result, :candlestick)
  end

  #Tasuki Gap
  def cdltasukigap(options={})
    idx_range = calc_indexes(:ta_cdltasukigap_lookback)
    result = Talib.ta_cdltasukigap(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdltasukigap, idx_range, options, result, :candlestick)
  end

  #Thrusting Pattern
  def cdlthrusting(options={})
    idx_range = calc_indexes(:ta_cdlthrusting_lookback)
    result = Talib.ta_cdlthrusting(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlthrusting, idx_range, options, result, :candlestick)
  end

  #Tristar Pattern
  def cdltristar(options={})
    idx_range = calc_indexes(:ta_cdltristar_lookback)
    result = Talib.ta_cdltristar(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdltristar, idx_range, options, result, :candlestick)
  end

  #Unique 3 River
  def cdlunique3river(options={})
    idx_range = calc_indexes(:ta_cdlunique3river_lookback)
    result = Talib.ta_cdlunique3river(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlunique3river, idx_range, options, result, :candlestick)
  end

  #Upside Gap Two Crows
  def cdlupsidegap2crows(options={})
    idx_range = calc_indexes(:ta_cdlupsidegap2crows_lookback)
    result = Talib.ta_cdlupsidegap2crows(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlupsidegap2crows, idx_range, options, result, :candlestick)
  end

  #Upside/Downside Gap Three Methods
  def cdlxsidegap3methods(options={})
    idx_range = calc_indexes(:ta_cdlxsidegap3methods_lookback)
    result = Talib.ta_cdlxsidegap3methods(idx_range.begin, idx_range.end, opening, high, low, close)
    memoize_result(self, :cdlxsidegap3methods, idx_range, options, result, :candlestick)
  end

  #Vector Ceil
  def ceil(inReal, options={})
    idx_range = calc_indexes(:ta_ceil_lookback)
    result = Talib.ta_ceil(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :ceil, idx_range, options, result)
  end

  #Chande Momentum Oscillator
  def cmo(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_cmo_lookback, options[:time_period])
    result = Talib.ta_cmo(idx_range.begin, idx_range.end, close, options[:time_period])
    memoize_result(self, :cmo, idx_range, options, result, :financebars)
  end

  #Pearson's Correlation Coefficient (r)
  def correl(inReal0, inReal1, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_correl_lookback, options[:time_period])
    result = Talib.ta_correl(idx_range.begin, idx_range.end, inReal0, inReal1, options[:time_period])
    memoize_result(self, :correl, idx_range, options, result)
  end

  #Vector Trigonometric Cos
  def cos(inReal, options={})
    idx_range = calc_indexes(:ta_cos_lookback)
    result = Talib.ta_cos(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :cos, idx_range, options, result)
  end

  #Vector Trigonometric Cosh
  def cosh(inReal, options={})
    idx_range = calc_indexes(:ta_cosh_lookback)
    result = Talib.ta_cosh(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :cosh, idx_range, options, result)
  end

  #Double Exponential Moving Average
  def dema(options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_dema_lookback, options[:time_period])
    result = Talib.ta_dema(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :dema, idx_range, options, result, :overlap)
  end

  #Vector Arithmetic Div
  def div(inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_div_lookback)
    result = Talib.ta_div(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(self, :div, idx_range, options, result)
  end

  #Directional Movement Index
  def dx(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_dx_lookback, options[:time_period])
    result = Talib.ta_dx(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :dx, idx_range, options, result, :unstable_period)
  end

  #Exponential Moving Average
  def ema(options={})
    options.reverse_merge!(:input => price, :time_period => 30)
    idx_range = calc_indexes(:ta_ema_lookback, options[:time_period])
    result = Talib.ta_ema(idx_range.begin, idx_range.end, options[:input], options[:time_period])
    memoize_result(self, :ema, idx_range, options, result, :overlap)
  end

  #Vector Arithmetic Exp
  def exp(inReal, options={})
    idx_range = calc_indexes(:ta_exp_lookback)
    result = Talib.ta_exp(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :exp, idx_range, options, result)
  end

  #Vector Floor
  def floor(inReal, options={})
    idx_range = calc_indexes(:ta_floor_lookback)
    result = Talib.ta_floor(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :floor, idx_range, options, result)
  end

  #Hilbert Transform - Dominant Cycle Period
  def ht_dcperiod(options={})
    idx_range = calc_indexes(:ta_ht_dcperiod_lookback)
    result = Talib.ta_ht_dcperiod(idx_range.begin, idx_range.end, price)
    memoize_result(self, :ht_dcperiod, idx_range, options, result)
  end

  #Hilbert Transform - Dominant Cycle Phase
  def ht_dcphase(options={})
    idx_range = calc_indexes(:ta_ht_dcphase_lookback)
    result = Talib.ta_ht_dcphase(idx_range.begin, idx_range.end, price)
    memoize_result(self, :ht_dcphase, idx_range, options, result)
  end

  #Hilbert Transform - Phasor Components
  def ht_phasor(options={})
    idx_range = calc_indexes(:ta_ht_phasor_lookback)
    result = Talib.ta_ht_phasor(idx_range.begin, idx_range.end, price)
    memoize_result(self, :ht_phasor, idx_range, options, result)
  end

  #Hilbert Transform - SineWave
  def ht_sine(options={})
    idx_range = calc_indexes(:ta_ht_sine_lookback)
    result = Talib.ta_ht_sine(idx_range.begin, idx_range.end, price)
    memoize_result(self, :ht_sine, idx_range, options, result)
  end

  #Hilbert Transform - Instantaneous Trendline
  def ht_trendline(options={})
    idx_range = calc_indexes(:ta_ht_trendline_lookback)
    result = Talib.ta_ht_trendline(idx_range.begin, idx_range.end, price)
    memoize_result(self, :ht_trendline, idx_range, options, result, :overlap)
  end

  #Hilbert Transform - Trend vs Cycle Mode
  def ht_trendmode(options={})
    idx_range = calc_indexes(:ta_ht_trendmode_lookback)
    result = Talib.ta_ht_trendmode(idx_range.begin, idx_range.end, price)
    memoize_result(self, :ht_trendmode, idx_range, options, result)
  end

  #Kaufman Adaptive Moving Average
  def kama(options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_kama_lookback, options[:time_period])
    result = Talib.ta_kama(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :kama, idx_range, options, result, :overlap)
  end

  #Linear Regression
  def linearreg(inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_lookback, options[:time_period])
    result = Talib.ta_linearreg(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :linearreg, idx_range, options, result, :overlap)
  end

  #Linear Regression Angle
  def linearreg_angle(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_angle_lookback, options[:time_period])
    result = Talib.ta_linearreg_angle(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :linearreg_angle, idx_range, options, result)
  end

  #Linear Regression Intercept
  def linearreg_intercept(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_intercept_lookback, options[:time_period])
    result = Talib.ta_linearreg_intercept(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :linearreg_intercept, idx_range, options, result, :overlap)
  end

  #Linear Regression Slope
  def linearreg_slope(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_slope_lookback, options[:time_period])
    result = Talib.ta_linearreg_slope(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :linearreg_slope, idx_range, options, result)
  end

  #Vector Log Natural
  def ln(inReal, options={})
    idx_range = calc_indexes(:ta_ln_lookback)
    result = Talib.ta_ln(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :ln, idx_range, options, result)
  end

  #Vector Log10
  def log10(inReal, options={})
    idx_range = calc_indexes(:ta_log10_lookback)
    result = Talib.ta_log10(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :log10, idx_range, options, result)
  end

  #Moving average
  def ma(options={})
    options.reverse_merge!(:time_period => 30, :ma_type => 0)
    idx_range = calc_indexes(:ta_ma_lookback, options[:time_period], options[:ma_type])
    result = Talib.ta_ma(idx_range.begin, idx_range.end, price, options[:time_period], options[:ma_type])
    memoize_result(self, :ma, idx_range, options, result, :overlap)
  end

  #Moving Average Convergence/Divergence
  def macd(options={})
    options.reverse_merge!(:fast_period => 12, :slow_period => 26, :signal_period => 9)
    idx_range = calc_indexes(:ta_macd_lookback, options[:fast_period], options[:slow_period], options[:signal_period])
    result = Talib.ta_macd(idx_range.begin, idx_range.end, price, options[:fast_period], options[:slow_period], options[:signal_period])
    memoize_result(self, :macd, idx_range, options, result)
  end

  #MACD with controllable MA type
  def macdext(options={})
    options.reverse_merge!(:fast_period => 12, :fast_ma => 1, :slow_period => 26, :slow_ma => 1, :signal_period => 9, :signal_ma => 1)
    idx_range = calc_indexes(:ta_macdext_lookback, options[:fast_period], options[:fast_ma], options[:slow_period], options[:slow_ma], options[:signal_period], options[:signal_ma])
    result = Talib.ta_macdext(idx_range.begin, idx_range.end, price, options[:fast_period], options[:fast_ma], options[:slow_period], options[:slow_ma], options[:signal_period], options[:signal_ma])
    memoize_result(self, :macdext, idx_range, options, result)
  end

  #Moving Average Convergence/Divergence Fix 12/26
  def macdfix(options={})
    options.reverse_merge!(:signal_period => 9)
    idx_range = calc_indexes(:ta_macdfix_lookback, options[:signal_period])
    result = Talib.ta_macdfix(idx_range.begin, idx_range.end, price, options[:signal_period])
    memoize_result(self, :macdfix, idx_range, options, result)
  end

  #MESA Adaptive Moving Average
  def mama(options={})
    options.reverse_merge!(:fast_limit => 0.5, :slow_limit => 0.05)
    idx_range = calc_indexes(:ta_mama_lookback, options[:fast_limit], options[:slow_limit])
    result = Talib.ta_mama(idx_range.begin, idx_range.end, price, options[:fast_limit], options[:slow_limit])
    memoize_result(self, :mama, idx_range, options, result, :overlap)
  end

  #Moving average with variable period
  def mavp(inPeriods, options={})
    options.reverse_merge!(:minimum_period => 2, :maximum_period => 30, :ma_type => 0)
    idx_range = calc_indexes(:ta_mavp_lookback, options[:minimum_period], options[:maximum_period], options[:ma_type])
    result = Talib.ta_mavp(idx_range.begin, idx_range.end, price, inPeriods, options[:minimum_period], options[:maximum_period], options[:ma_type])
    memoize_result(self, :mavp, idx_range, options, result, :overlap)
  end

  #Highest value over a specified period
  def max(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_max_lookback, options[:time_period])
    result = Talib.ta_max(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :max, idx_range, options, result, :overlap)
  end

  #Index of highest value over a specified period
  def maxindex(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_maxindex_lookback, options[:time_period])
    result = Talib.ta_maxindex(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :maxindex, idx_range, options, result)
  end

  #Median Price
  def medprice(options={})
    idx_range = calc_indexes(:ta_medprice_lookback)
    result = Talib.ta_medprice(idx_range.begin, idx_range.end, high, low)
    memoize_result(self, :medprice, idx_range, options, result, :overlap)
  end

  #Money Flow Index
  def mfi(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_mfi_lookback, options[:time_period])
    result = Talib.ta_mfi(idx_range.begin, idx_range.end, high, low, close, volume, options[:time_period])
    memoize_result(self, :mfi, idx_range, options, result, :financebars)
  end

  #MidPoint over period
  def midpoint(inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_midpoint_lookback, options[:time_period])
    result = Talib.ta_midpoint(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :midpoint, idx_range, options, result, :overlap)
  end

  #Midpoint Price over period
  def midprice(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_midprice_lookback, options[:time_period])
    result = Talib.ta_midprice(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(self, :midprice, idx_range, options, result, :overlap)
  end

  #Lowest value over a specified period
  def min(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_min_lookback, options[:time_period])
    result = Talib.ta_min(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :min, idx_range, options, result, :overlap)
  end

  #Index of lowest value over a specified period
  def minindex(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_minindex_lookback, options[:time_period])
    result = Talib.ta_minindex(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :minindex, idx_range, options, result)
  end

  #Lowest and highest values over a specified period
  def minmax(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_minmax_lookback, options[:time_period])
    result = Talib.ta_minmax(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :minmax, idx_range, options, result, :overlap)
  end

  #Indexes of lowest and highest values over a specified period
  def minmaxindex(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_minmaxindex_lookback, options[:time_period])
    result = Talib.ta_minmaxindex(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :minmaxindex, idx_range, options, result)
  end

  #Minus Directional Indicator
  def minus_di(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_minus_di_lookback, options[:time_period])
    result = Talib.ta_minus_di(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :minus_di, idx_range, options, result, :unstable_period)
  end

  #Minus Directional Movement
  def minus_dm(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_minus_dm_lookback, options[:time_period])
    result = Talib.ta_minus_dm(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(self, :minus_dm, idx_range, options, result, :unstable_period)
  end

  #Momentum
  def mom(options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_mom_lookback, options[:time_period])
    result = Talib.ta_mom(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :mom, idx_range, options, result)
  end

  #Vector Arithmetic Mult
  def mult(inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_mult_lookback)
    result = Talib.ta_mult(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(self, :mult, idx_range, options, result)
  end

  #Normalized Average True Range
  def natr(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_natr_lookback, options[:time_period])
    result = Talib.ta_natr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :natr, idx_range, options, result, :unstable_period)
  end

  #On Balance Volume
  def obv(options={})
    idx_range = calc_indexes(:ta_obv_lookback)
    result = Talib.ta_obv(idx_range.begin, idx_range.end, close, volume)
    memoize_result(self, :obv, idx_range, options, result)
  end

  #Plus Directional Indicator
  def plus_di(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_plus_di_lookback, options[:time_period])
    result = Talib.ta_plus_di(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :plus_di, idx_range, options, result, :unstable_period)
  end

  #Plus Directional Movement
  def plus_dm(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_plus_dm_lookback, options[:time_period])
    result = Talib.ta_plus_dm(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(self, :plus_dm, idx_range, options, result, :unstable_period)
  end

  #Percentage Price Oscillator
  def ppo(options={})
    options.reverse_merge!(:fast_period => 12, :slow_period => 26, :ma_type => 0)
    idx_range = calc_indexes(:ta_ppo_lookback, options[:fast_period], options[:slow_period], options[:ma_type])
    result = Talib.ta_ppo(idx_range.begin, idx_range.end, price, options[:fast_period], options[:slow_period], options[:ma_type])
    memoize_result(self, :ppo, idx_range, options, result)
  end

  #Rate of change : ((price/prevPrice)-1)*100
  def roc(options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_roc_lookback, options[:time_period])
    result = Talib.ta_roc(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :roc, idx_range, options, result)
  end

  #Rate of change Percentage: (price-prevPrice)/prevPrice
  def rocp(options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_rocp_lookback, options[:time_period])
    result = Talib.ta_rocp(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :rocp, idx_range, options, result)
  end

  #Rate of change ratio: (price/prevPrice)
  def rocr(options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_rocr_lookback, options[:time_period])
    result = Talib.ta_rocr(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :rocr, idx_range, options, result)
  end

  #Rate of change ratio 100 scale: (price/prevPrice)*100
  def rocr100(options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_rocr100_lookback, options[:time_period])
    result = Talib.ta_rocr100(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :rocr100, idx_range, options, result)
  end

  #Relative Strength Index
  def rsi(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_rsi_lookback, options[:time_period])
    result = Talib.ta_rsi(idx_range.begin, idx_range.end, close, options[:time_period])
    memoize_result(self, :rsi, idx_range, options, result, :financebars)
  end

  #Parabolic SAR
  def sar(options={})
    options.reverse_merge!(:acceleration_factor => 0.02, :af_maximum => 0.2)
    idx_range = calc_indexes(:ta_sar_lookback, options[:acceleration_factor], options[:af_maximum])
    result = Talib.ta_sar(idx_range.begin, idx_range.end, high, low, options[:acceleration_factor], options[:af_maximum])
    memoize_result(self, :sar, idx_range, options, result, :overlap)
  end

  #Parabolic SAR - Extended
  def sarext(options={})
    options.reverse_merge!(:start_value => 0.0, :offset_on_reverse => 0.0, :af_init_long => 0.02, :af_long => 0.02, :af_max_long => 0.2, :af_init_short => 0.02, :af_short => 0.02, :af_max_short => 0.2)
    idx_range = calc_indexes(:ta_sarext_lookback, options[:start_value], options[:offset_on_reverse], options[:af_init_long], options[:af_long], options[:af_max_long], options[:af_init_short], options[:af_short], options[:af_max_short])
    result = Talib.ta_sarext(idx_range.begin, idx_range.end, high, low, options[:start_value], options[:offset_on_reverse], options[:af_init_long], options[:af_long], options[:af_max_long], options[:af_init_short], options[:af_short], options[:af_max_short])
    memoize_result(self, :sarext, idx_range, options, result, :overlap)
  end

  #Vector Trigonometric Sin
  def sin(inReal, options={})
    idx_range = calc_indexes(:ta_sin_lookback)
    result = Talib.ta_sin(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :sin, idx_range, options, result)
  end

  #Vector Trigonometric Sinh
  def sinh(inReal, options={})
    idx_range = calc_indexes(:ta_sinh_lookback)
    result = Talib.ta_sinh(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :sinh, idx_range, options, result)
  end

  #Simple Moving Average
  def sma(options={})
    options.reverse_merge!(:time_period => 30, :input => price)
    idx_range = calc_indexes(:ta_sma_lookback, options[:time_period])
    result = Talib.ta_sma(idx_range.begin, idx_range.end, options[:input], options[:time_period])
    memoize_result(self, :sma, idx_range, options, result, :overlap)
  end

  #Vector Square Root
  def sqrt(inReal, options={})
    idx_range = calc_indexes(:ta_sqrt_lookback)
    result = Talib.ta_sqrt(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :sqrt, idx_range, options, result)
  end

  #Standard Deviation
  def stddev(inReal, options={})
    options.reverse_merge!(:time_period => 5, :deviations => 1.0)
    idx_range = calc_indexes(:ta_stddev_lookback, options[:time_period], options[:deviations])
    result = Talib.ta_stddev(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:deviations])
    memoize_result(self, :stddev, idx_range, options, result)
  end

  #Stochastic
  def stoch(options={})
    options.reverse_merge!(:fast_k_period => 5, :slow_k_period => 3, :slow_k_ma => 0, :slow_d_period => 3, :slow_d_ma => 0)
    idx_range = calc_indexes(:ta_stoch_lookback, options[:fast_k_period], options[:slow_k_period], options[:slow_k_ma], options[:slow_d_period], options[:slow_d_ma])
    result = Talib.ta_stoch(idx_range.begin, idx_range.end, high, low, close, options[:fast_k_period], options[:slow_k_period], options[:slow_k_ma], options[:slow_d_period], options[:slow_d_ma])
    memoize_result(self, :stoch, idx_range, options, result)
  end

  #Stochastic Fast
  def stochf(options={})
    options.reverse_merge!(:fast_k_period => 5, :fast_d_period => 3, :fast_d_ma => 0)
    idx_range = calc_indexes(:ta_stochf_lookback, options[:fast_k_period], options[:fast_d_period], options[:fast_d_ma])
    result = Talib.ta_stochf(idx_range.begin, idx_range.end, high, low, close, options[:fast_k_period], options[:fast_d_period], options[:fast_d_ma])
    memoize_result(self, :stochf, idx_range, options, result)
  end

  #Stochastic Relative Strength Index
  def stochrsi(options={})
    options.reverse_merge!(:time_period => 14, :fast_k_period => 5, :fast_d_period => 3, :fast_d_ma => 0)
    idx_range = calc_indexes(:ta_stochrsi_lookback, options[:time_period], options[:fast_k_period], options[:fast_d_period], options[:fast_d_ma])
    result = Talib.ta_stochrsi(idx_range.begin, idx_range.end, price, options[:time_period], options[:fast_k_period], options[:fast_d_period], options[:fast_d_ma])
    memoize_result(self, :stochrsi, idx_range, options, result, :financebars)
  end

  #Vector Arithmetic Substraction
  def sub(inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_sub_lookback)
    result = Talib.ta_sub(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(self, :sub, idx_range, options, result)
  end

  #Summation
  def sum(inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_sum_lookback, options[:time_period])
    result = Talib.ta_sum(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(self, :sum, idx_range, options, result)
  end

  #Triple Exponential Moving Average (T3)
  def t3(options={})
    options.reverse_merge!(:time_period => 5, :volume_factor => 0.7)
    idx_range = calc_indexes(:ta_t3_lookback, options[:time_period], options[:volume_factor])
    result = Talib.ta_t3(idx_range.begin, idx_range.end, price, options[:time_period], options[:volume_factor])
    memoize_result(self, :t3, idx_range, options, result, :overlap)
  end

  #Vector Trigonometric Tan
  def tan(inReal, options={})
    idx_range = calc_indexes(:ta_tan_lookback)
    result = Talib.ta_tan(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :tan, idx_range, options, result)
  end

  #Vector Trigonometric Tanh
  def tanh(inReal, options={})
    idx_range = calc_indexes(:ta_tanh_lookback)
    result = Talib.ta_tanh(idx_range.begin, idx_range.end, inReal)
    memoize_result(self, :tanh, idx_range, options, result)
  end

  #Triple Exponential Moving Average
  def tema(options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_tema_lookback, options[:time_period])
    result = Talib.ta_tema(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :tema, idx_range, options, result, :overlap)
  end

  #True Range
  def trange(options={})
    idx_range = calc_indexes(:ta_trange_lookback)
    result = Talib.ta_trange(idx_range.begin, idx_range.end, high, low, close)
    memoize_result(self, :trange, idx_range, options, result)
  end

  #Triangular Moving Average
  def trima(options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_trima_lookback, options[:time_period])
    result = Talib.ta_trima(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :trima, idx_range, options, result, :overlap)
  end

  #1-day Rate-Of-Change (ROC) of a Triple Smooth EMA
  def trix(options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_trix_lookback, options[:time_period])
    result = Talib.ta_trix(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :trix, idx_range, options, result)
  end

  #Time Series Forecast
  def tsf(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_tsf_lookback, options[:time_period])
    result = Talib.ta_tsf(idx_range.begin, idx_range.end, close, options[:time_period])
    memoize_result(self, :tsf, idx_range, options, result, :overlap)
  end

  #Typical Price
  def typprice(options={})
    idx_range = calc_indexes(:ta_typprice_lookback)
    result = Talib.ta_typprice(idx_range.begin, idx_range.end, high, low, close)
    memoize_result(self, :typprice, idx_range, options, result, :overlap)
  end

  #Ultimate Oscillator
  def ultosc(options={})
    options.reverse_merge!(:first_period => 7, :second_period => 14, :third_period => 28)
    idx_range = calc_indexes(:ta_ultosc_lookback, options[:first_period], options[:second_period], options[:third_period])
    result = Talib.ta_ultosc(idx_range.begin, idx_range.end, high, low, close, options[:first_period], options[:second_period], options[:third_period])
    memoize_result(self, :ultosc, idx_range, options, result)
  end

  #Variance
  def var(options={})
    options.reverse_merge!(:time_period => 5, :deviations => 1.0)
    idx_range = calc_indexes(:ta_var_lookback, options[:time_period], options[:deviations])
    result = Talib.ta_var(idx_range.begin, idx_range.end, price, options[:time_period], options[:deviations])
    memoize_result(self, :var, idx_range, options, result)
  end

  #Weighted Close Price
  def wclprice(options={})
    idx_range = calc_indexes(:ta_wclprice_lookback)
    result = Talib.ta_wclprice(idx_range.begin, idx_range.end, high, low, close)
    memoize_result(self, :wclprice, idx_range, options, result, :overlap)
  end

  #Williams' %R
  def willr(options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_willr_lookback, options[:time_period])
    result = Talib.ta_willr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(self, :willr, idx_range, options, result)
  end

  #Weighted Moving Average
  def wma(options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_wma_lookback, options[:time_period])
    result = Talib.ta_wma(idx_range.begin, idx_range.end, price, options[:time_period])
    memoize_result(self, :wma, idx_range, options, result, :overlap)
  end
end

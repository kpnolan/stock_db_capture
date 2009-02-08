    ###############################################################################################################
    # DON'T EDIT THIS FILE !!!
    # This file was automatically generated from 'ta_func.xml'
    # If, for some reason the interface to Talib changes, but the Swig I/F file 'ta_func.swg' must change as well
    # as 'ta_func.xml'. This file contains the "shadow methods" that the writers of the SWIG I/F deemed unneccessary.
    # I think the Swig interface is still to low-level and created this higher-level interface that really is designed
    # to be a mixin to the Timeseries class upon with talib functions operate.
    ################################################################################################################
module TechnicalAnalysis
  #Vector Trigonometric ACos
  def acos(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_acos_lookback, time_range)
    result = Talib.ta_acos(idx_range.begin, idx_range.end, inReal)
    memoize_result(:acos, time_range, idx_range, options, result)
  end

  #Chaikin A/D Line
  def ad(time_range, options={})
    idx_range = calc_indexes(:ta_ad_lookback, time_range)
    result = Talib.ta_ad(idx_range.begin, idx_range.end, high, low, close, volume)
    memoize_result(:ad, time_range, idx_range, options, result)
  end

  #Vector Arithmetic Add
  def add(time_range, inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_add_lookback, time_range)
    result = Talib.ta_add(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(:add, time_range, idx_range, options, result)
  end

  #Chaikin A/D Oscillator
  def adosc(time_range, options={})
    options.reverse_merge!(:fast_period => 3, :slow_period => 10)
    idx_range = calc_indexes(:ta_adosc_lookback, time_range, options[:fast_period], options[:slow_period])
    result = Talib.ta_adosc(idx_range.begin, idx_range.end, high, low, close, volume, options[:fast_period], options[:slow_period])
    memoize_result(:adosc, time_range, idx_range, options, result)
  end

  #Average Directional Movement Index
  def adx(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_adx_lookback, time_range, options[:time_period])
    result = Talib.ta_adx(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:adx, time_range, idx_range, options, result, :unstable_period)
  end

  #Average Directional Movement Index Rating
  def adxr(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_adxr_lookback, time_range, options[:time_period])
    result = Talib.ta_adxr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:adxr, time_range, idx_range, options, result, :unstable_period)
  end

  #Absolute Price Oscillator
  def apo(time_range, inReal, options={})
    options.reverse_merge!(:fast_period => 12, :slow_period => 26, :ma_type => 0)
    idx_range = calc_indexes(:ta_apo_lookback, time_range, options[:fast_period], options[:slow_period], options[:ma_type])
    result = Talib.ta_apo(idx_range.begin, idx_range.end, inReal, options[:fast_period], options[:slow_period], options[:ma_type])
    memoize_result(:apo, time_range, idx_range, options, result)
  end

  #Aroon
  def aroon(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_aroon_lookback, time_range, options[:time_period])
    result = Talib.ta_aroon(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(:aroon, time_range, idx_range, options, result)
  end

  #Aroon Oscillator
  def aroonosc(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_aroonosc_lookback, time_range, options[:time_period])
    result = Talib.ta_aroonosc(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(:aroonosc, time_range, idx_range, options, result)
  end

  #Vector Trigonometric ASin
  def asin(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_asin_lookback, time_range)
    result = Talib.ta_asin(idx_range.begin, idx_range.end, inReal)
    memoize_result(:asin, time_range, idx_range, options, result)
  end

  #Vector Trigonometric ATan
  def atan(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_atan_lookback, time_range)
    result = Talib.ta_atan(idx_range.begin, idx_range.end, inReal)
    memoize_result(:atan, time_range, idx_range, options, result)
  end

  #Average True Range
  def atr(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_atr_lookback, time_range, options[:time_period])
    result = Talib.ta_atr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:atr, time_range, idx_range, options, result, :unstable_period)
  end

  #Average Price
  def avgprice(time_range, options={})
    idx_range = calc_indexes(:ta_avgprice_lookback, time_range)
    result = Talib.ta_avgprice(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:avgprice, time_range, idx_range, options, result, :overlap)
  end

  #Bollinger Bands
  def bbands(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 5, :deviations_up => 2.0, :deviations_down => 2.0, :ma_type => 0)
    idx_range = calc_indexes(:ta_bbands_lookback, time_range, options[:time_period], options[:deviations_up], options[:deviations_down], options[:ma_type])
    result = Talib.ta_bbands(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:deviations_up], options[:deviations_down], options[:ma_type])
    memoize_result(:bbands, time_range, idx_range, options, result, :overlap)
  end

  #Beta
  def beta(time_range, inReal0, inReal1, options={})
    options.reverse_merge!(:time_period => 5)
    idx_range = calc_indexes(:ta_beta_lookback, time_range, options[:time_period])
    result = Talib.ta_beta(idx_range.begin, idx_range.end, inReal0, inReal1, options[:time_period])
    memoize_result(:beta, time_range, idx_range, options, result)
  end

  #Balance Of Power
  def bop(time_range, options={})
    idx_range = calc_indexes(:ta_bop_lookback, time_range)
    result = Talib.ta_bop(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:bop, time_range, idx_range, options, result)
  end

  #Commodity Channel Index
  def cci(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_cci_lookback, time_range, options[:time_period])
    result = Talib.ta_cci(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:cci, time_range, idx_range, options, result)
  end

  #Two Crows
  def cdl2crows(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_2crows_lookback, time_range)
    result = Talib.ta_cdl_2crows(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl2crows, time_range, idx_range, options, result, :candlestick)
  end

  #Three Black Crows
  def cdl3blackcrows(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_3blackcrows_lookback, time_range)
    result = Talib.ta_cdl_3blackcrows(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl3blackcrows, time_range, idx_range, options, result, :candlestick)
  end

  #Three Inside Up/Down
  def cdl3inside(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_3inside_lookback, time_range)
    result = Talib.ta_cdl_3inside(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl3inside, time_range, idx_range, options, result, :candlestick)
  end

  #Three-Line Strike
  def cdl3linestrike(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_3linestrike_lookback, time_range)
    result = Talib.ta_cdl_3linestrike(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl3linestrike, time_range, idx_range, options, result, :candlestick)
  end

  #Three Outside Up/Down
  def cdl3outside(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_3outside_lookback, time_range)
    result = Talib.ta_cdl_3outside(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl3outside, time_range, idx_range, options, result, :candlestick)
  end

  #Three Stars In The South
  def cdl3starsinsouth(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_3starsinsouth_lookback, time_range)
    result = Talib.ta_cdl_3starsinsouth(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl3starsinsouth, time_range, idx_range, options, result, :candlestick)
  end

  #Three Advancing White Soldiers
  def cdl3whitesoldiers(time_range, options={})
    idx_range = calc_indexes(:ta_cdl_3whitesoldiers_lookback, time_range)
    result = Talib.ta_cdl_3whitesoldiers(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdl3whitesoldiers, time_range, idx_range, options, result, :candlestick)
  end

  #Abandoned Baby
  def cdlabandonedbaby(time_range, options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdlabandonedbaby_lookback, time_range, options[:penetration])
    result = Talib.ta_cdlabandonedbaby(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdlabandonedbaby, time_range, idx_range, options, result, :candlestick)
  end

  #Advance Block
  def cdladvanceblock(time_range, options={})
    idx_range = calc_indexes(:ta_cdladvanceblock_lookback, time_range)
    result = Talib.ta_cdladvanceblock(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdladvanceblock, time_range, idx_range, options, result, :candlestick)
  end

  #Belt-hold
  def cdlbelthold(time_range, options={})
    idx_range = calc_indexes(:ta_cdlbelthold_lookback, time_range)
    result = Talib.ta_cdlbelthold(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlbelthold, time_range, idx_range, options, result, :candlestick)
  end

  #Breakaway
  def cdlbreakaway(time_range, options={})
    idx_range = calc_indexes(:ta_cdlbreakaway_lookback, time_range)
    result = Talib.ta_cdlbreakaway(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlbreakaway, time_range, idx_range, options, result, :candlestick)
  end

  #Closing Marubozu
  def cdlclosingmarubozu(time_range, options={})
    idx_range = calc_indexes(:ta_cdlclosingmarubozu_lookback, time_range)
    result = Talib.ta_cdlclosingmarubozu(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlclosingmarubozu, time_range, idx_range, options, result, :candlestick)
  end

  #Concealing Baby Swallow
  def cdlconcealbabyswall(time_range, options={})
    idx_range = calc_indexes(:ta_cdlconcealbabyswall_lookback, time_range)
    result = Talib.ta_cdlconcealbabyswall(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlconcealbabyswall, time_range, idx_range, options, result, :candlestick)
  end

  #Counterattack
  def cdlcounterattack(time_range, options={})
    idx_range = calc_indexes(:ta_cdlcounterattack_lookback, time_range)
    result = Talib.ta_cdlcounterattack(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlcounterattack, time_range, idx_range, options, result, :candlestick)
  end

  #Dark Cloud Cover
  def cdldarkcloudcover(time_range, options={})
    options.reverse_merge!(:penetration => 0.5)
    idx_range = calc_indexes(:ta_cdldarkcloudcover_lookback, time_range, options[:penetration])
    result = Talib.ta_cdldarkcloudcover(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdldarkcloudcover, time_range, idx_range, options, result, :candlestick)
  end

  #Doji
  def cdldoji(time_range, options={})
    idx_range = calc_indexes(:ta_cdldoji_lookback, time_range)
    result = Talib.ta_cdldoji(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdldoji, time_range, idx_range, options, result, :candlestick)
  end

  #Doji Star
  def cdldojistar(time_range, options={})
    idx_range = calc_indexes(:ta_cdldojistar_lookback, time_range)
    result = Talib.ta_cdldojistar(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdldojistar, time_range, idx_range, options, result, :candlestick)
  end

  #Dragonfly Doji
  def cdldragonflydoji(time_range, options={})
    idx_range = calc_indexes(:ta_cdldragonflydoji_lookback, time_range)
    result = Talib.ta_cdldragonflydoji(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdldragonflydoji, time_range, idx_range, options, result, :candlestick)
  end

  #Engulfing Pattern
  def cdlengulfing(time_range, options={})
    idx_range = calc_indexes(:ta_cdlengulfing_lookback, time_range)
    result = Talib.ta_cdlengulfing(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlengulfing, time_range, idx_range, options, result, :candlestick)
  end

  #Evening Doji Star
  def cdleveningdojistar(time_range, options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdleveningdojistar_lookback, time_range, options[:penetration])
    result = Talib.ta_cdleveningdojistar(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdleveningdojistar, time_range, idx_range, options, result, :candlestick)
  end

  #Evening Star
  def cdleveningstar(time_range, options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdleveningstar_lookback, time_range, options[:penetration])
    result = Talib.ta_cdleveningstar(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdleveningstar, time_range, idx_range, options, result, :candlestick)
  end

  #Up/Down-gap side-by-side white lines
  def cdlgapsidesidewhite(time_range, options={})
    idx_range = calc_indexes(:ta_cdlgapsidesidewhite_lookback, time_range)
    result = Talib.ta_cdlgapsidesidewhite(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlgapsidesidewhite, time_range, idx_range, options, result, :candlestick)
  end

  #Gravestone Doji
  def cdlgravestonedoji(time_range, options={})
    idx_range = calc_indexes(:ta_cdlgravestonedoji_lookback, time_range)
    result = Talib.ta_cdlgravestonedoji(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlgravestonedoji, time_range, idx_range, options, result, :candlestick)
  end

  #Hammer
  def cdlhammer(time_range, options={})
    idx_range = calc_indexes(:ta_cdlhammer_lookback, time_range)
    result = Talib.ta_cdlhammer(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlhammer, time_range, idx_range, options, result, :candlestick)
  end

  #Hanging Man
  def cdlhangingman(time_range, options={})
    idx_range = calc_indexes(:ta_cdlhangingman_lookback, time_range)
    result = Talib.ta_cdlhangingman(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlhangingman, time_range, idx_range, options, result, :candlestick)
  end

  #Harami Pattern
  def cdlharami(time_range, options={})
    idx_range = calc_indexes(:ta_cdlharami_lookback, time_range)
    result = Talib.ta_cdlharami(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlharami, time_range, idx_range, options, result, :candlestick)
  end

  #Harami Cross Pattern
  def cdlharamicross(time_range, options={})
    idx_range = calc_indexes(:ta_cdlharamicross_lookback, time_range)
    result = Talib.ta_cdlharamicross(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlharamicross, time_range, idx_range, options, result, :candlestick)
  end

  #High-Wave Candle
  def cdlhighwave(time_range, options={})
    idx_range = calc_indexes(:ta_cdlhighwave_lookback, time_range)
    result = Talib.ta_cdlhighwave(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlhighwave, time_range, idx_range, options, result, :candlestick)
  end

  #Hikkake Pattern
  def cdlhikkake(time_range, options={})
    idx_range = calc_indexes(:ta_cdlhikkake_lookback, time_range)
    result = Talib.ta_cdlhikkake(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlhikkake, time_range, idx_range, options, result, :candlestick)
  end

  #Modified Hikkake Pattern
  def cdlhikkakemod(time_range, options={})
    idx_range = calc_indexes(:ta_cdlhikkakemod_lookback, time_range)
    result = Talib.ta_cdlhikkakemod(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlhikkakemod, time_range, idx_range, options, result, :candlestick)
  end

  #Homing Pigeon
  def cdlhomingpigeon(time_range, options={})
    idx_range = calc_indexes(:ta_cdlhomingpigeon_lookback, time_range)
    result = Talib.ta_cdlhomingpigeon(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlhomingpigeon, time_range, idx_range, options, result, :candlestick)
  end

  #Identical Three Crows
  def cdlidentical3crows(time_range, options={})
    idx_range = calc_indexes(:ta_cdlidentical3crows_lookback, time_range)
    result = Talib.ta_cdlidentical3crows(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlidentical3crows, time_range, idx_range, options, result, :candlestick)
  end

  #In-Neck Pattern
  def cdlinneck(time_range, options={})
    idx_range = calc_indexes(:ta_cdlinneck_lookback, time_range)
    result = Talib.ta_cdlinneck(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlinneck, time_range, idx_range, options, result, :candlestick)
  end

  #Inverted Hammer
  def cdlinvertedhammer(time_range, options={})
    idx_range = calc_indexes(:ta_cdlinvertedhammer_lookback, time_range)
    result = Talib.ta_cdlinvertedhammer(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlinvertedhammer, time_range, idx_range, options, result, :candlestick)
  end

  #Kicking
  def cdlkicking(time_range, options={})
    idx_range = calc_indexes(:ta_cdlkicking_lookback, time_range)
    result = Talib.ta_cdlkicking(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlkicking, time_range, idx_range, options, result, :candlestick)
  end

  #Kicking - bull/bear determined by the longer marubozu
  def cdlkickingbylength(time_range, options={})
    idx_range = calc_indexes(:ta_cdlkickingbylength_lookback, time_range)
    result = Talib.ta_cdlkickingbylength(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlkickingbylength, time_range, idx_range, options, result, :candlestick)
  end

  #Ladder Bottom
  def cdlladderbottom(time_range, options={})
    idx_range = calc_indexes(:ta_cdlladderbottom_lookback, time_range)
    result = Talib.ta_cdlladderbottom(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlladderbottom, time_range, idx_range, options, result, :candlestick)
  end

  #Long Legged Doji
  def cdllongleggeddoji(time_range, options={})
    idx_range = calc_indexes(:ta_cdllongleggeddoji_lookback, time_range)
    result = Talib.ta_cdllongleggeddoji(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdllongleggeddoji, time_range, idx_range, options, result, :candlestick)
  end

  #Long Line Candle
  def cdllongline(time_range, options={})
    idx_range = calc_indexes(:ta_cdllongline_lookback, time_range)
    result = Talib.ta_cdllongline(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdllongline, time_range, idx_range, options, result, :candlestick)
  end

  #Marubozu
  def cdlmarubozu(time_range, options={})
    idx_range = calc_indexes(:ta_cdlmarubozu_lookback, time_range)
    result = Talib.ta_cdlmarubozu(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlmarubozu, time_range, idx_range, options, result, :candlestick)
  end

  #Matching Low
  def cdlmatchinglow(time_range, options={})
    idx_range = calc_indexes(:ta_cdlmatchinglow_lookback, time_range)
    result = Talib.ta_cdlmatchinglow(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlmatchinglow, time_range, idx_range, options, result, :candlestick)
  end

  #Mat Hold
  def cdlmathold(time_range, options={})
    options.reverse_merge!(:penetration => 0.5)
    idx_range = calc_indexes(:ta_cdlmathold_lookback, time_range, options[:penetration])
    result = Talib.ta_cdlmathold(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdlmathold, time_range, idx_range, options, result, :candlestick)
  end

  #Morning Doji Star
  def cdlmorningdojistar(time_range, options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdlmorningdojistar_lookback, time_range, options[:penetration])
    result = Talib.ta_cdlmorningdojistar(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdlmorningdojistar, time_range, idx_range, options, result, :candlestick)
  end

  #Morning Star
  def cdlmorningstar(time_range, options={})
    options.reverse_merge!(:penetration => 0.3)
    idx_range = calc_indexes(:ta_cdlmorningstar_lookback, time_range, options[:penetration])
    result = Talib.ta_cdlmorningstar(idx_range.begin, idx_range.end, open, high, low, close, options[:penetration])
    memoize_result(:cdlmorningstar, time_range, idx_range, options, result, :candlestick)
  end

  #On-Neck Pattern
  def cdlonneck(time_range, options={})
    idx_range = calc_indexes(:ta_cdlonneck_lookback, time_range)
    result = Talib.ta_cdlonneck(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlonneck, time_range, idx_range, options, result, :candlestick)
  end

  #Piercing Pattern
  def cdlpiercing(time_range, options={})
    idx_range = calc_indexes(:ta_cdlpiercing_lookback, time_range)
    result = Talib.ta_cdlpiercing(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlpiercing, time_range, idx_range, options, result, :candlestick)
  end

  #Rickshaw Man
  def cdlrickshawman(time_range, options={})
    idx_range = calc_indexes(:ta_cdlrickshawman_lookback, time_range)
    result = Talib.ta_cdlrickshawman(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlrickshawman, time_range, idx_range, options, result, :candlestick)
  end

  #Rising/Falling Three Methods
  def cdlrisefall3methods(time_range, options={})
    idx_range = calc_indexes(:ta_cdlrisefall3methods_lookback, time_range)
    result = Talib.ta_cdlrisefall3methods(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlrisefall3methods, time_range, idx_range, options, result, :candlestick)
  end

  #Separating Lines
  def cdlseparatinglines(time_range, options={})
    idx_range = calc_indexes(:ta_cdlseparatinglines_lookback, time_range)
    result = Talib.ta_cdlseparatinglines(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlseparatinglines, time_range, idx_range, options, result, :candlestick)
  end

  #Shooting Star
  def cdlshootingstar(time_range, options={})
    idx_range = calc_indexes(:ta_cdlshootingstar_lookback, time_range)
    result = Talib.ta_cdlshootingstar(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlshootingstar, time_range, idx_range, options, result, :candlestick)
  end

  #Short Line Candle
  def cdlshortline(time_range, options={})
    idx_range = calc_indexes(:ta_cdlshortline_lookback, time_range)
    result = Talib.ta_cdlshortline(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlshortline, time_range, idx_range, options, result, :candlestick)
  end

  #Spinning Top
  def cdlspinningtop(time_range, options={})
    idx_range = calc_indexes(:ta_cdlspinningtop_lookback, time_range)
    result = Talib.ta_cdlspinningtop(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlspinningtop, time_range, idx_range, options, result, :candlestick)
  end

  #Stalled Pattern
  def cdlstalledpattern(time_range, options={})
    idx_range = calc_indexes(:ta_cdlstalledpattern_lookback, time_range)
    result = Talib.ta_cdlstalledpattern(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlstalledpattern, time_range, idx_range, options, result, :candlestick)
  end

  #Stick Sandwich
  def cdlsticksandwich(time_range, options={})
    idx_range = calc_indexes(:ta_cdlsticksandwich_lookback, time_range)
    result = Talib.ta_cdlsticksandwich(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlsticksandwich, time_range, idx_range, options, result, :candlestick)
  end

  #Takuri (Dragonfly Doji with very long lower shadow)
  def cdltakuri(time_range, options={})
    idx_range = calc_indexes(:ta_cdltakuri_lookback, time_range)
    result = Talib.ta_cdltakuri(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdltakuri, time_range, idx_range, options, result, :candlestick)
  end

  #Tasuki Gap
  def cdltasukigap(time_range, options={})
    idx_range = calc_indexes(:ta_cdltasukigap_lookback, time_range)
    result = Talib.ta_cdltasukigap(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdltasukigap, time_range, idx_range, options, result, :candlestick)
  end

  #Thrusting Pattern
  def cdlthrusting(time_range, options={})
    idx_range = calc_indexes(:ta_cdlthrusting_lookback, time_range)
    result = Talib.ta_cdlthrusting(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlthrusting, time_range, idx_range, options, result, :candlestick)
  end

  #Tristar Pattern
  def cdltristar(time_range, options={})
    idx_range = calc_indexes(:ta_cdltristar_lookback, time_range)
    result = Talib.ta_cdltristar(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdltristar, time_range, idx_range, options, result, :candlestick)
  end

  #Unique 3 River
  def cdlunique3river(time_range, options={})
    idx_range = calc_indexes(:ta_cdlunique3river_lookback, time_range)
    result = Talib.ta_cdlunique3river(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlunique3river, time_range, idx_range, options, result, :candlestick)
  end

  #Upside Gap Two Crows
  def cdlupsidegap2crows(time_range, options={})
    idx_range = calc_indexes(:ta_cdlupsidegap2crows_lookback, time_range)
    result = Talib.ta_cdlupsidegap2crows(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlupsidegap2crows, time_range, idx_range, options, result, :candlestick)
  end

  #Upside/Downside Gap Three Methods
  def cdlxsidegap3methods(time_range, options={})
    idx_range = calc_indexes(:ta_cdlxsidegap3methods_lookback, time_range)
    result = Talib.ta_cdlxsidegap3methods(idx_range.begin, idx_range.end, open, high, low, close)
    memoize_result(:cdlxsidegap3methods, time_range, idx_range, options, result, :candlestick)
  end

  #Vector Ceil
  def ceil(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ceil_lookback, time_range)
    result = Talib.ta_ceil(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ceil, time_range, idx_range, options, result)
  end

  #Chande Momentum Oscillator
  def cmo(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_cmo_lookback, time_range, options[:time_period])
    result = Talib.ta_cmo(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:cmo, time_range, idx_range, options, result, :unstable_period)
  end

  #Pearson's Correlation Coefficient (r)
  def correl(time_range, inReal0, inReal1, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_correl_lookback, time_range, options[:time_period])
    result = Talib.ta_correl(idx_range.begin, idx_range.end, inReal0, inReal1, options[:time_period])
    memoize_result(:correl, time_range, idx_range, options, result)
  end

  #Vector Trigonometric Cos
  def cos(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_cos_lookback, time_range)
    result = Talib.ta_cos(idx_range.begin, idx_range.end, inReal)
    memoize_result(:cos, time_range, idx_range, options, result)
  end

  #Vector Trigonometric Cosh
  def cosh(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_cosh_lookback, time_range)
    result = Talib.ta_cosh(idx_range.begin, idx_range.end, inReal)
    memoize_result(:cosh, time_range, idx_range, options, result)
  end

  #Double Exponential Moving Average
  def dema(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_dema_lookback, time_range, options[:time_period])
    result = Talib.ta_dema(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:dema, time_range, idx_range, options, result, :overlap)
  end

  #Vector Arithmetic Div
  def div(time_range, inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_div_lookback, time_range)
    result = Talib.ta_div(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(:div, time_range, idx_range, options, result)
  end

  #Directional Movement Index
  def dx(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_dx_lookback, time_range, options[:time_period])
    result = Talib.ta_dx(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:dx, time_range, idx_range, options, result, :unstable_period)
  end

  #Exponential Moving Average
  def ema(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_ema_lookback, time_range, options[:time_period])
    result = Talib.ta_ema(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:ema, time_range, idx_range, options, result, :overlap)
  end

  #Vector Arithmetic Exp
  def exp(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_exp_lookback, time_range)
    result = Talib.ta_exp(idx_range.begin, idx_range.end, inReal)
    memoize_result(:exp, time_range, idx_range, options, result)
  end

  #Vector Floor
  def floor(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_floor_lookback, time_range)
    result = Talib.ta_floor(idx_range.begin, idx_range.end, inReal)
    memoize_result(:floor, time_range, idx_range, options, result)
  end

  #Hilbert Transform - Dominant Cycle Period
  def ht_dcperiod(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ht_dcperiod_lookback, time_range)
    result = Talib.ta_ht_dcperiod(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ht_dcperiod, time_range, idx_range, options, result, :unstable_period)
  end

  #Hilbert Transform - Dominant Cycle Phase
  def ht_dcphase(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ht_dcphase_lookback, time_range)
    result = Talib.ta_ht_dcphase(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ht_dcphase, time_range, idx_range, options, result, :unstable_period)
  end

  #Hilbert Transform - Phasor Components
  def ht_phasor(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ht_phasor_lookback, time_range)
    result = Talib.ta_ht_phasor(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ht_phasor, time_range, idx_range, options, result, :unstable_period)
  end

  #Hilbert Transform - SineWave
  def ht_sine(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ht_sine_lookback, time_range)
    result = Talib.ta_ht_sine(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ht_sine, time_range, idx_range, options, result, :unstable_period)
  end

  #Hilbert Transform - Instantaneous Trendline
  def ht_trendline(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ht_trendline_lookback, time_range)
    result = Talib.ta_ht_trendline(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ht_trendline, time_range, idx_range, options, result, :overlap)
  end

  #Hilbert Transform - Trend vs Cycle Mode
  def ht_trendmode(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ht_trendmode_lookback, time_range)
    result = Talib.ta_ht_trendmode(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ht_trendmode, time_range, idx_range, options, result, :unstable_period)
  end

  #Kaufman Adaptive Moving Average
  def kama(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_kama_lookback, time_range, options[:time_period])
    result = Talib.ta_kama(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:kama, time_range, idx_range, options, result, :overlap)
  end

  #Linear Regression
  def linearreg(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_lookback, time_range, options[:time_period])
    result = Talib.ta_linearreg(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:linearreg, time_range, idx_range, options, result, :overlap)
  end

  #Linear Regression Angle
  def linearreg_angle(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_angle_lookback, time_range, options[:time_period])
    result = Talib.ta_linearreg_angle(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:linearreg_angle, time_range, idx_range, options, result)
  end

  #Linear Regression Intercept
  def linearreg_intercept(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_intercept_lookback, time_range, options[:time_period])
    result = Talib.ta_linearreg_intercept(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:linearreg_intercept, time_range, idx_range, options, result, :overlap)
  end

  #Linear Regression Slope
  def linearreg_slope(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_linearreg_slope_lookback, time_range, options[:time_period])
    result = Talib.ta_linearreg_slope(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:linearreg_slope, time_range, idx_range, options, result)
  end

  #Vector Log Natural
  def ln(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_ln_lookback, time_range)
    result = Talib.ta_ln(idx_range.begin, idx_range.end, inReal)
    memoize_result(:ln, time_range, idx_range, options, result)
  end

  #Vector Log10
  def log10(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_log10_lookback, time_range)
    result = Talib.ta_log10(idx_range.begin, idx_range.end, inReal)
    memoize_result(:log10, time_range, idx_range, options, result)
  end

  #Moving average
  def ma(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30, :ma_type => 0)
    idx_range = calc_indexes(:ta_ma_lookback, time_range, options[:time_period], options[:ma_type])
    result = Talib.ta_ma(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:ma_type])
    memoize_result(:ma, time_range, idx_range, options, result, :overlap)
  end

  #Moving Average Convergence/Divergence
  def macd(time_range, inReal, options={})
    options.reverse_merge!(:fast_period => 12, :slow_period => 26, :signal_period => 9)
    idx_range = calc_indexes(:ta_macd_lookback, time_range, options[:fast_period], options[:slow_period], options[:signal_period])
    result = Talib.ta_macd(idx_range.begin, idx_range.end, inReal, options[:fast_period], options[:slow_period], options[:signal_period])
    memoize_result(:macd, time_range, idx_range, options, result)
  end

  #MACD with controllable MA type
  def macdext(time_range, inReal, options={})
    options.reverse_merge!(:fast_period => 12, :fast_ma => 0, :slow_period => 26, :slow_ma => 0, :signal_period => 9, :signal_ma => 0)
    idx_range = calc_indexes(:ta_macdext_lookback, time_range, options[:fast_period], options[:fast_ma], options[:slow_period], options[:slow_ma], options[:signal_period], options[:signal_ma])
    result = Talib.ta_macdext(idx_range.begin, idx_range.end, inReal, options[:fast_period], options[:fast_ma], options[:slow_period], options[:slow_ma], options[:signal_period], options[:signal_ma])
    memoize_result(:macdext, time_range, idx_range, options, result)
  end

  #Moving Average Convergence/Divergence Fix 12/26
  def macdfix(time_range, inReal, options={})
    options.reverse_merge!(:signal_period => 9)
    idx_range = calc_indexes(:ta_macdfix_lookback, time_range, options[:signal_period])
    result = Talib.ta_macdfix(idx_range.begin, idx_range.end, inReal, options[:signal_period])
    memoize_result(:macdfix, time_range, idx_range, options, result)
  end

  #MESA Adaptive Moving Average
  def mama(time_range, inReal, options={})
    options.reverse_merge!(:fast_limit => 0.5, :slow_limit => 0.05)
    idx_range = calc_indexes(:ta_mama_lookback, time_range, options[:fast_limit], options[:slow_limit])
    result = Talib.ta_mama(idx_range.begin, idx_range.end, inReal, options[:fast_limit], options[:slow_limit])
    memoize_result(:mama, time_range, idx_range, options, result, :overlap)
  end

  #Moving average with variable period
  def mavp(time_range, inReal, inPeriods, options={})
    options.reverse_merge!(:minimum_period => 2, :maximum_period => 30, :ma_type => 0)
    idx_range = calc_indexes(:ta_mavp_lookback, time_range, options[:minimum_period], options[:maximum_period], options[:ma_type])
    result = Talib.ta_mavp(idx_range.begin, idx_range.end, inReal, inPeriods, options[:minimum_period], options[:maximum_period], options[:ma_type])
    memoize_result(:mavp, time_range, idx_range, options, result, :overlap)
  end

  #Highest value over a specified period
  def max(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_max_lookback, time_range, options[:time_period])
    result = Talib.ta_max(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:max, time_range, idx_range, options, result, :overlap)
  end

  #Index of highest value over a specified period
  def maxindex(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_maxindex_lookback, time_range, options[:time_period])
    result = Talib.ta_maxindex(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:maxindex, time_range, idx_range, options, result)
  end

  #Median Price
  def medprice(time_range, options={})
    idx_range = calc_indexes(:ta_medprice_lookback, time_range)
    result = Talib.ta_medprice(idx_range.begin, idx_range.end, high, low)
    memoize_result(:medprice, time_range, idx_range, options, result, :overlap)
  end

  #Money Flow Index
  def mfi(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_mfi_lookback, time_range, options[:time_period])
    result = Talib.ta_mfi(idx_range.begin, idx_range.end, high, low, close, volume, options[:time_period])
    memoize_result(:mfi, time_range, idx_range, options, result, :unstable_period)
  end

  #MidPoint over period
  def midpoint(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_midpoint_lookback, time_range, options[:time_period])
    result = Talib.ta_midpoint(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:midpoint, time_range, idx_range, options, result, :overlap)
  end

  #Midpoint Price over period
  def midprice(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_midprice_lookback, time_range, options[:time_period])
    result = Talib.ta_midprice(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(:midprice, time_range, idx_range, options, result, :overlap)
  end

  #Lowest value over a specified period
  def min(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_min_lookback, time_range, options[:time_period])
    result = Talib.ta_min(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:min, time_range, idx_range, options, result, :overlap)
  end

  #Index of lowest value over a specified period
  def minindex(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_minindex_lookback, time_range, options[:time_period])
    result = Talib.ta_minindex(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:minindex, time_range, idx_range, options, result)
  end

  #Lowest and highest values over a specified period
  def minmax(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_minmax_lookback, time_range, options[:time_period])
    result = Talib.ta_minmax(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:minmax, time_range, idx_range, options, result, :overlap)
  end

  #Indexes of lowest and highest values over a specified period
  def minmaxindex(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_minmaxindex_lookback, time_range, options[:time_period])
    result = Talib.ta_minmaxindex(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:minmaxindex, time_range, idx_range, options, result)
  end

  #Minus Directional Indicator
  def minus_di(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_minus_di_lookback, time_range, options[:time_period])
    result = Talib.ta_minus_di(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:minus_di, time_range, idx_range, options, result, :unstable_period)
  end

  #Minus Directional Movement
  def minus_dm(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_minus_dm_lookback, time_range, options[:time_period])
    result = Talib.ta_minus_dm(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(:minus_dm, time_range, idx_range, options, result, :unstable_period)
  end

  #Momentum
  def mom(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_mom_lookback, time_range, options[:time_period])
    result = Talib.ta_mom(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:mom, time_range, idx_range, options, result)
  end

  #Vector Arithmetic Mult
  def mult(time_range, inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_mult_lookback, time_range)
    result = Talib.ta_mult(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(:mult, time_range, idx_range, options, result)
  end

  #Normalized Average True Range
  def natr(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_natr_lookback, time_range, options[:time_period])
    result = Talib.ta_natr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:natr, time_range, idx_range, options, result, :unstable_period)
  end

  #On Balance Volume
  def obv(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_obv_lookback, time_range)
    result = Talib.ta_obv(idx_range.begin, idx_range.end, inRealvolume)
    memoize_result(:obv, time_range, idx_range, options, result)
  end

  #Plus Directional Indicator
  def plus_di(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_plus_di_lookback, time_range, options[:time_period])
    result = Talib.ta_plus_di(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:plus_di, time_range, idx_range, options, result, :unstable_period)
  end

  #Plus Directional Movement
  def plus_dm(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_plus_dm_lookback, time_range, options[:time_period])
    result = Talib.ta_plus_dm(idx_range.begin, idx_range.end, high, low, options[:time_period])
    memoize_result(:plus_dm, time_range, idx_range, options, result, :unstable_period)
  end

  #Percentage Price Oscillator
  def ppo(time_range, inReal, options={})
    options.reverse_merge!(:fast_period => 12, :slow_period => 26, :ma_type => 0)
    idx_range = calc_indexes(:ta_ppo_lookback, time_range, options[:fast_period], options[:slow_period], options[:ma_type])
    result = Talib.ta_ppo(idx_range.begin, idx_range.end, inReal, options[:fast_period], options[:slow_period], options[:ma_type])
    memoize_result(:ppo, time_range, idx_range, options, result)
  end

  #Rate of change : ((price/prevPrice)-1)*100
  def roc(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_roc_lookback, time_range, options[:time_period])
    result = Talib.ta_roc(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:roc, time_range, idx_range, options, result)
  end

  #Rate of change Percentage: (price-prevPrice)/prevPrice
  def rocp(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_rocp_lookback, time_range, options[:time_period])
    result = Talib.ta_rocp(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:rocp, time_range, idx_range, options, result)
  end

  #Rate of change ratio: (price/prevPrice)
  def rocr(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_rocr_lookback, time_range, options[:time_period])
    result = Talib.ta_rocr(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:rocr, time_range, idx_range, options, result)
  end

  #Rate of change ratio 100 scale: (price/prevPrice)*100
  def rocr100(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 10)
    idx_range = calc_indexes(:ta_rocr100_lookback, time_range, options[:time_period])
    result = Talib.ta_rocr100(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:rocr100, time_range, idx_range, options, result)
  end

  #Relative Strength Index
  def rsi(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_rsi_lookback, time_range, options[:time_period])
    result = Talib.ta_rsi(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:rsi, time_range, idx_range, options, result, :unstable_period)
  end

  #Parabolic SAR
  def sar(time_range, options={})
    options.reverse_merge!(:acceleration_factor => 0.02, :af_maximum => 0.2)
    idx_range = calc_indexes(:ta_sar_lookback, time_range, options[:acceleration_factor], options[:af_maximum])
    result = Talib.ta_sar(idx_range.begin, idx_range.end, high, low, options[:acceleration_factor], options[:af_maximum])
    memoize_result(:sar, time_range, idx_range, options, result, :overlap)
  end

  #Parabolic SAR - Extended
  def sarext(time_range, options={})
    options.reverse_merge!(:start_value => 0.0, :offset_on_reverse => 0.0, :af_init_long => 0.02, :af_long => 0.02, :af_max_long => 0.2, :af_init_short => 0.02, :af_short => 0.02, :af_max_short => 0.2)
    idx_range = calc_indexes(:ta_sarext_lookback, time_range, options[:start_value], options[:offset_on_reverse], options[:af_init_long], options[:af_long], options[:af_max_long], options[:af_init_short], options[:af_short], options[:af_max_short])
    result = Talib.ta_sarext(idx_range.begin, idx_range.end, high, low, options[:start_value], options[:offset_on_reverse], options[:af_init_long], options[:af_long], options[:af_max_long], options[:af_init_short], options[:af_short], options[:af_max_short])
    memoize_result(:sarext, time_range, idx_range, options, result, :overlap)
  end

  #Vector Trigonometric Sin
  def sin(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_sin_lookback, time_range)
    result = Talib.ta_sin(idx_range.begin, idx_range.end, inReal)
    memoize_result(:sin, time_range, idx_range, options, result)
  end

  #Vector Trigonometric Sinh
  def sinh(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_sinh_lookback, time_range)
    result = Talib.ta_sinh(idx_range.begin, idx_range.end, inReal)
    memoize_result(:sinh, time_range, idx_range, options, result)
  end

  #Simple Moving Average
  def sma(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_sma_lookback, time_range, options[:time_period])
    result = Talib.ta_sma(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:sma, time_range, idx_range, options, result, :overlap)
  end

  #Vector Square Root
  def sqrt(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_sqrt_lookback, time_range)
    result = Talib.ta_sqrt(idx_range.begin, idx_range.end, inReal)
    memoize_result(:sqrt, time_range, idx_range, options, result)
  end

  #Standard Deviation
  def stddev(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 5, :deviations => 1.0)
    idx_range = calc_indexes(:ta_stddev_lookback, time_range, options[:time_period], options[:deviations])
    result = Talib.ta_stddev(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:deviations])
    memoize_result(:stddev, time_range, idx_range, options, result)
  end

  #Stochastic
  def stoch(time_range, options={})
    options.reverse_merge!(:fast-k_period => 5, :slow-k_period => 3, :slow-k_ma => 0, :slow-d_period => 3, :slow-d_ma => 0)
    idx_range = calc_indexes(:ta_stoch_lookback, time_range, options[:fast-k_period], options[:slow-k_period], options[:slow-k_ma], options[:slow-d_period], options[:slow-d_ma])
    result = Talib.ta_stoch(idx_range.begin, idx_range.end, high, low, close, options[:fast-k_period], options[:slow-k_period], options[:slow-k_ma], options[:slow-d_period], options[:slow-d_ma])
    memoize_result(:stoch, time_range, idx_range, options, result)
  end

  #Stochastic Fast
  def stochf(time_range, options={})
    options.reverse_merge!(:fast-k_period => 5, :fast-d_period => 3, :fast-d_ma => 0)
    idx_range = calc_indexes(:ta_stochf_lookback, time_range, options[:fast-k_period], options[:fast-d_period], options[:fast-d_ma])
    result = Talib.ta_stochf(idx_range.begin, idx_range.end, high, low, close, options[:fast-k_period], options[:fast-d_period], options[:fast-d_ma])
    memoize_result(:stochf, time_range, idx_range, options, result)
  end

  #Stochastic Relative Strength Index
  def stochrsi(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14, :fast-k_period => 5, :fast-d_period => 3, :fast-d_ma => 0)
    idx_range = calc_indexes(:ta_stochrsi_lookback, time_range, options[:time_period], options[:fast-k_period], options[:fast-d_period], options[:fast-d_ma])
    result = Talib.ta_stochrsi(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:fast-k_period], options[:fast-d_period], options[:fast-d_ma])
    memoize_result(:stochrsi, time_range, idx_range, options, result, :unstable_period)
  end

  #Vector Arithmetic Substraction
  def sub(time_range, inReal0, inReal1, options={})
    idx_range = calc_indexes(:ta_sub_lookback, time_range)
    result = Talib.ta_sub(idx_range.begin, idx_range.end, inReal0, inReal1)
    memoize_result(:sub, time_range, idx_range, options, result)
  end

  #Summation
  def sum(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_sum_lookback, time_range, options[:time_period])
    result = Talib.ta_sum(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:sum, time_range, idx_range, options, result)
  end

  #Triple Exponential Moving Average (T3)
  def t3(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 5, :volume_factor => 0.7)
    idx_range = calc_indexes(:ta_t3_lookback, time_range, options[:time_period], options[:volume_factor])
    result = Talib.ta_t3(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:volume_factor])
    memoize_result(:t3, time_range, idx_range, options, result, :overlap)
  end

  #Vector Trigonometric Tan
  def tan(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_tan_lookback, time_range)
    result = Talib.ta_tan(idx_range.begin, idx_range.end, inReal)
    memoize_result(:tan, time_range, idx_range, options, result)
  end

  #Vector Trigonometric Tanh
  def tanh(time_range, inReal, options={})
    idx_range = calc_indexes(:ta_tanh_lookback, time_range)
    result = Talib.ta_tanh(idx_range.begin, idx_range.end, inReal)
    memoize_result(:tanh, time_range, idx_range, options, result)
  end

  #Triple Exponential Moving Average
  def tema(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_tema_lookback, time_range, options[:time_period])
    result = Talib.ta_tema(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:tema, time_range, idx_range, options, result, :overlap)
  end

  #True Range
  def trange(time_range, options={})
    idx_range = calc_indexes(:ta_trange_lookback, time_range)
    result = Talib.ta_trange(idx_range.begin, idx_range.end, high, low, close)
    memoize_result(:trange, time_range, idx_range, options, result)
  end

  #Triangular Moving Average
  def trima(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_trima_lookback, time_range, options[:time_period])
    result = Talib.ta_trima(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:trima, time_range, idx_range, options, result, :overlap)
  end

  #1-day Rate-Of-Change (ROC) of a Triple Smooth EMA
  def trix(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_trix_lookback, time_range, options[:time_period])
    result = Talib.ta_trix(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:trix, time_range, idx_range, options, result)
  end

  #Time Series Forecast
  def tsf(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_tsf_lookback, time_range, options[:time_period])
    result = Talib.ta_tsf(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:tsf, time_range, idx_range, options, result, :overlap)
  end

  #Typical Price
  def typprice(time_range, options={})
    idx_range = calc_indexes(:ta_typprice_lookback, time_range)
    result = Talib.ta_typprice(idx_range.begin, idx_range.end, high, low, close)
    memoize_result(:typprice, time_range, idx_range, options, result, :overlap)
  end

  #Ultimate Oscillator
  def ultosc(time_range, options={})
    options.reverse_merge!(:first_period => 7, :second_period => 14, :third_period => 28)
    idx_range = calc_indexes(:ta_ultosc_lookback, time_range, options[:first_period], options[:second_period], options[:third_period])
    result = Talib.ta_ultosc(idx_range.begin, idx_range.end, high, low, close, options[:first_period], options[:second_period], options[:third_period])
    memoize_result(:ultosc, time_range, idx_range, options, result)
  end

  #Variance
  def var(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 5, :deviations => 1.0)
    idx_range = calc_indexes(:ta_var_lookback, time_range, options[:time_period], options[:deviations])
    result = Talib.ta_var(idx_range.begin, idx_range.end, inReal, options[:time_period], options[:deviations])
    memoize_result(:var, time_range, idx_range, options, result)
  end

  #Weighted Close Price
  def wclprice(time_range, options={})
    idx_range = calc_indexes(:ta_wclprice_lookback, time_range)
    result = Talib.ta_wclprice(idx_range.begin, idx_range.end, high, low, close)
    memoize_result(:wclprice, time_range, idx_range, options, result, :overlap)
  end

  #Williams' %R
  def willr(time_range, options={})
    options.reverse_merge!(:time_period => 14)
    idx_range = calc_indexes(:ta_willr_lookback, time_range, options[:time_period])
    result = Talib.ta_willr(idx_range.begin, idx_range.end, high, low, close, options[:time_period])
    memoize_result(:willr, time_range, idx_range, options, result)
  end

  #Weighted Moving Average
  def wma(time_range, inReal, options={})
    options.reverse_merge!(:time_period => 30)
    idx_range = calc_indexes(:ta_wma_lookback, time_range, options[:time_period])
    result = Talib.ta_wma(idx_range.begin, idx_range.end, inReal, options[:time_period])
    memoize_result(:wma, time_range, idx_range, options, result, :overlap)
  end

end

# Class: Timeseries
#
# This is the work-horse class for the entire reset of the system.
# Every sample of bar data is eventually converted to a timeseries
# upon with every indicator must operate.
# An element of a Timeseries is an entire bar (OHLCV) + logr (log return).
# A Timerseries can have gaps and can have multiple resolutions, e.g. daily, intraday(5,6,15,30)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'date'

class Time
  def bod?; hour == 9 && min == 30;end
  def eod?; hour == 15 && min == 30; end
  def in_trade?; hour >= 9 && hour <= 15; end
end

class Timeseries

  include Plot
  include TechnicalAnalysis
  include UserAnalysis
  include CompositeAnalysis
  include ResultAnalysis
  include CsvDumper
  include Enumerable

  TRADING_PERIOD = 6.hours + 30.minutes
  PRECALC_BARS = 50
  POSTCALC_BARS = 30

  DEFAULT_OPTIONS = { DailyBar => { :sample_resolution => [ 1.day ]   },
                      IntraDayBar => { :sample_resolution => [ 30.minutes ]  } }

  attr_reader :symbol, :ticker_id, :model, :value_hash, :enum_index, :enum_attrs, :model_attrs, :bars_per_day
  attr_reader :begin_time, :end_time, :utc_offset, :resolution, :options
  attr_reader :attrs, :derived_values, :output_offset, :stride, :stride_offset, :only
  attr_reader :timevec, :time_map, :local_range, :price, :index_range, :begin_index, :end_index
  attr_reader :expected_bar_count, :expected_trading_days

  def initialize(symbol_or_id, local_range, time_resolution=1.day, options={})
    @options = options.reverse_merge :price => :default, :pre_buffer => true, :populate => true, :post_buffer => false
    initialize_state()
    @ticker_id = Ticker.resolve_id(symbol_or_id)
    raise ArgumentError, "Excpecting ticker symbol or ticker id as first argument. Neither could be found" if ticker_id.nil?
    @symbol = Ticker.find(ticker_id).symbol
    if local_range.is_a? Range
      if local_range.begin.is_a?(Date) && local_range.end.is_a?(Date)
        @local_range = local_range.begin.to_time.utc.midnight..local_range.end.to_time.utc.midnight
      elsif local_range.begin.is_a?(Time) && local_range.end.is_a?(Time)
        @local_range = local_range.begin.utc..local_range.end.utc
      else
        raise ArgumentError, "local_range must be a Date, a Range of Dates or Times, or String"
      end
    else
      if local_range.is_a?(Date)
        @local_range = local_range.to_time.utc.midnight..(local_range.to_time.utc.midnight + 1.day)
      elsif local_range.is_a?(String)
        @local_range = parse_local_string(local_range)
      else
        raise ArgumentError, "local_range must be a Date, a Range of Dates or Times, or String"
      end
    end

    @model, @model_attrs = select_by_resolution(time_resolution)
    @resolution = time_resolution
    @bars_per_day =  resolution == 1.day ? 1 : TRADING_PERIOD / resolution
    @attrs = model.content_columns.map { |c| c.name.to_sym }
    set_enum_attrs(attrs)
    @stride = options[:stride].nil? ? 1 :  options[:stride]
    @stride_offset = options[:stride_offset].nil? ? 0 : options[:stride_offset]
    raise ArgumentError, "Stride offset with no stride makes no sense also stride_offset must be < stride" if stride && stride_offset >= stride
    pre_offset = calc_prebuffer()
    post_offset = options[:post_buffer] == true ? POSTCALC_BARS : options[:post_buffer].is_a?(Fixnum) ? options[:post_buffer] : 0
    @begin_time = offset_date(@local_range.begin, -pre_offset)
    @end_time = (od = offset_date(@local_range.end, post_offset)) > Time.now ? Time.now : od
    @expected_trading_days = trading_days(begin_time.to_date..end_time.to_date)
    @expected_bar_count =  expected_trading_days.length * bars_per_day
    options.reverse_merge!(DEFAULT_OPTIONS[model])
    options[:populate] ? repopulate({}) : init_timevec
    add_methods_for_attributes(value_hash.keys)
    set_price(options[:price])
  end

  #
  # Parse a date/time string with the nominal format (see 2nd arg to strptime)
  # returning a time have the local timezone
  #
  def self.parse_time(date_time_str, fmt="%m/%d/%Y %H:%M")
    d = Date._strptime(date_time_str, fmt)
    Time.local(d[:year], d[:mon], d[:mday], d[:hour], d[:min],
               d[:sec], d[:sec_fraction], d[:zone])
  end

  #
  # return a string summarizing the contents of this Timeseries
  #
  def to_s
    "#{symbol} #{local_range.begin}-#{local_range.end} #{timevec.length} data values"
  end

  def inspect
    super
  end

  #
  # Return the offset into the timeseries of the first result, whcih has to be the same
  # as the beginning of the actual timeseries (minus any pre-buffering). We pre-buffer PRECALC_BARS
  # elements by default so that any TA methods (EMAs, SMAs, etc) which require extra elements
  # to "warm up" the compuation have their needs meet by the pre-buffering. W/O pre-buffering
  # the the "warm up" elements would be taken out of the actually data series, causing the first
  # output to be some number of elements in (which would be bad).
  #
  def outidx
    @index_range.begin
  end

  #
  # The method was added as a convenience method for generating Lewis's spreadsheets. The idea was that he
  # could select a subset of the values in a bar for reporting on the timesheet. It's basically a hack
  # and should be taken out. It was put in so that the "each" method (and therefore all Enumeration methods)
  # could be used on a timeseries.
  #
  def set_enum_attrs(subset)
    raise ArgumentError, "attrs is not a proper subset of available values" unless subset.all? { |attr| attrs.include? attr }
    @enum_attrs = subset
  end

  #
  # The is the "each" mentioned above. Notice that it only yields the preselected enum variables
  #
  def each
    @timevec.each_with_index { |time,i | v = values_at(i, *enum_attrs);  yield v }
  end

  #
  # yields a hash whose keys are *attrs* for every bar in the input time range
  #
  def local_each(attrs)
    timevec[index_range].each_with_index { |time, i| yield hash_at(i, attrs).merge({ :time => time}) }
  end
  #
  # returns a *hash* of values the keys of which are *attrs* for the index specified
  #
  def hash_at(i, attrs)
    attrs.inject({}) { |a, h| h[a] = value_hash[a][i]; h}
  end
  #
  # Convenience methods that runs all the specified technical analysis function in one line, i.e:
  #    $ts.all :rsi, :rvi, :ema, :lr
  # Instead of having to specify them on seperate lines.
  #
  def all(*args)
    multi_calc(args)
  end

  #
  # Return all values (OHLC...) for a given Timeseries index. This really should be superceeded with
  # a non-hacked iterator like each
  def values_at(index, vals)
    vals = vals.map { |v| value_hash[v][index] }
  end

  #
  # This is like all() only it allows for the specification of parameters that apply to all of the functions
  #
  def multi_calc(fcn_vec, options={})
    return nil if fcn_vec.empty?
    fcn_vec.each { |function| send(function, options.merge(:plot_results => true)) }
    aggregate_all(symbol, options.merge(:multiplot => true, :with => 'financebars'))
    clear_results
  end


  #
  # Like multi_calc but take a vector of function, paramater paris
  #
  def multi_fopt(fopt_vec, options={})
    fopt_vec.each do |ary|
      raise ArgumentError, "Expecting an Array of [:function, {options}]" unless ary.is_a? Array
      send(ary.first, ary.last.merge(:plot_results => true))
    end
    aggregate_all(symbol, options.merge(:multiplot => true, :with => 'financebars'))
    clear_results
  end

  #
  # Find the first result returned by a saved fucnction, most function have only one vector of outputs
  #
  def find_result(fcn, options={})
    values = derived_values.reverse.select { |pb| pb.match(fcn, options) }
    if options[:all]
      values
    else
      return values.first unless values.empty?
    end
  end

  #
  # Clears the objects retaining the results of prior TA calles
  #
  def clear_results
    @derived_values = []
  end

  #
  # Returns the results of a prior TA call, takes a symbol or pair [ :fcn, :result_name ]
  #
  def vector_for(sym_or_pair)
    derived_values.each do |memo|
      case
      when sym_or_pair.is_a?(Symbol) &&
           memo.result_hash.has_key?(sym_or_pair)                       : return memo.result_hash[sym_or_pair]
      when sym_or_pair.is_a?(Array) && sym_or_pair.first == memo.fcn &&
           memo.result_hash.hash_key?(sym_or_pair.second)               : return memo.result_hash[sym_or_pair.second]
      end
    end
    if sym_or_pair.is_a?(Symbol) && value_hash.has_key?(sym_or_pair)
      value_hash[sym_or_pair][index_range].to_gv
    else
      raise ArgumentError, "Cannot find #{sym_or_pair}"
    end
  end

  #
  # Sets the vector, either directly or by computing it, of the vector known as price with most TALIB
  # function use as their source vector
  #
  def set_price(expression = :default)
    @price = case
             when expression == :default      : close
             when expression == :average      : (high+low).scale(0.5)
             when expression == :all          : (open+close+high+low).scale(0.25)
             when expression.is_a?(Symbol)    : send(expression)
             when expression.is_a?(String)    : instance_eval(expression)
             end
  end

  #
  # Selects the DB model containing the resolution (1.day, 30.minutes, 5.minute) of the bars
  #
  def select_by_resolution(resolution)
    DEFAULT_OPTIONS.each_pair do |key, value|
      return key, value if value[:sample_resolution].include? resolution
    end
    raise ArgumentError, "A sampling resolution of #{resolution} is not available"
  end

  #
  # Compute the calendar date to be given to the DB to grab the selected data range plus any pre-buffering
  #
  def offset_date(ref_date, offset)
    trading_days = ((1.day / bars_per_day ) * offset) /1.day
    tdf = trading_days_from(ref_date, trading_days).last.to_time.utc.midnight
  end

  #
  # initializes the time vector for this time series
  #
  def init_timevec
    value_hash[model.time_col.to_sym] ||= model.time_vector(symbol, begin_time, end_time)
    compute_timestamps
  end

  #
  # Populates the timeseries with the results stored in the DB. This is resolution agnostic.
  # If the Timeseries whas specified with a stride, repopulated Timeseries with just the values
  # according to the stride and stride offset.
  #
  def repopulate(options)
    @value_hash = model.general_vectors(symbol, attrs, begin_time, end_time)
    missing_bars = expected_bar_count - value_hash[:close].length
    raise TimeseriesException, "No values where returned from #{model.to_s.tableize} for #{symbol} " +
      "#{begin_time.to_s(:db)} through #{end_time.to_s(:db)}" if value_hash.empty?
    if missing_bars > 0 and model == DailyBar
      @expected_timevec ||= expected_trading_days.map { |td| td.to_time.utc.midnight }
      compute_timestamps()
      rejects = @expected_timevec.reject { |t| time_map.include?(t) }.map { |t| t.to_date.to_s(:db) }
      raise TimeseriesException, "Missing #{missing_bars} bars: #{rejects.join(', ')} for #{symbol}" if missing_bars > 0
    elsif missing_bars > 0
      raise TimeseriesException, "Missing #{missing_bars} bars for #{symbol}"
    end
    if stride > 1
      new_hash = { }
      value_hash.each_pair do |k,v|
        vec = []
        v.each_with_index { |e,i| vec << e if i % stride == stride_offset }
        new_hash[k] = vec
      end
      @value_hash = new_hash
    end
    compute_timestamps
  end

#  private

  #
  # sets a local variable to the options supplied with the function call.
  #
  def apply_options(options)
    options.keys.each do |key|
      send("#{key}=", options[key]) if respond_to? key
    end
  end

  #
  # Central routine handlling the normalization a storage of the time values returned from the database
  #
  def compute_timestamps
    if model.time_class == Date
      @timevec = value_hash[model.time_col.to_sym].collect { |dt| dt.to_time.utc.midnight }
    else
      @timevec = value_hash[model.time_col.to_sym]
    end
    timevec.each_with_index { |time, idx| @time_map[time] = idx }
    @begin_index = time2index(local_range.begin, 1)
    @end_index = time2index(local_range.end, -1)
    @index_range = begin_index..end_index
  end

  #
  # Retuns the minimal number of samples a TA function needs. The value will be then used
  # to check if we have buffered enough samples before the begining of the real data so that
  # we get a full vector of results
  #
  def minimal_samples(lookback_fun, *args)
    lookback_fun ? Talib.send(lookback_fun, *args) : args.sum
  end

  # FIXME outidx is unique to function and params and so much be indexed as such!!!!!!!!!!!!!!!!!!

  def calc_indexes(loopback_fun, *args)
    @output_offset = begin_index >= (ms = minimal_samples(loopback_fun, *args)) ? 0 : ms - begin_index
    debugger if output_offset > 0
    #raise ArgumentError, "Only subset of Date Range available for #{symbol}, pre-buffer at least #{output_offset} more bars" if output_offset > 0
    index_range
  end

  #
  # Maps the time or data to the specific index in the vector for the sample associated with that date/time
  #
  def time2index(time, direction, raise_on_range_error=true)
    case
    when model.time_class == Date : time2index_days(time, direction, raise_on_range_error=true)
    when model.time_class == Time : time2index_time(time, direction, raise_on_range_error=true)
    else debugger
    end
  end

  #
  # Handles dates only, delegated to from time2index
  #
  def time2index_days(time, direction, raise_on_range_error)
    adj_time = time.to_time.utc.midnight
    if direction == -1
      raise TimeseriesException, "#{symbol}: requested time: #{adj_time} is before recorded history: starting #{timevec.first}" if adj_time < timevec.first
      until time_map.include?(adj_time) || adj_time < timevec.first
        adj_time -= resolution
      end
      raise TimeseriesException, "#{time} is not contained within the DB" if time_map[adj_time].nil?
      time_map[adj_time]
    else # this is split into two loop to simplify the boundry test
      raise TimeseriesException, "Requested time: #{adj_time} is after recorded history: ending #{timevec.last}" if adj_time > timevec.last
      until time_map.include?(adj_time) || adj_time > timevec.last
        adj_time += resolution
      end
    end
    raise TimeseriesException.new, "#{time} is not contained within the DB" if time_map[adj_time].nil?
    return time_map[adj_time]
  end

  #
  # Handles times only, delegated to from time2index
  #
  def time2index_time(time, direction, raise_on_range_error=true)
    adj_time = time.at_midnight ? ETZ.local(time.year, time.month, time.day, 9, 30, 0) : time
    if direction == -1
      raise TimeseriesException, "#{symbol}: requested time is before recorded history: starting #{timevec.first}" if adj_time < timevec.first
      until time_map.include?(adj_time) || adj_time < timevec.first
        adj_time -= resolution
      end
      raise TimeseriesException, "#{time} is not contained within the DB" if time_map[adj_time].nil?
      time_map[adj_time]
    else # this is split into two loop to simplify the boundry test
      raise TimeseriesException, "Requested time is after recorded history: ending #{timevec.last}" if adj_time > timevec.last
      until time_map.include?(adj_time) || adj_time > timevec.last
        adj_time += resolution
      end
    end
    raise TimeseriesException, "#{time} is not contained within the DB" if time_map[adj_time].nil?
    return time_map[adj_time]
  end

  #
  # Returns a the value at an index location of a bar or result #FIXME this function is duplicated elswhere
  #
  def values_at(index, *slots)
    slots.map { |s| value_hash[s][index]}
  end

  def value_at(index, slot)
    value_hash[slot][index]
  end
  #
  # Returns the time for a vector of index
  #
  def times_for(indexes)
    indexes.map { |index| index2time(index) }
  end

  #
  # returns the time for a specific index
  #
  def index2time(index, offset=0)
    return nil if index >= timevec.length
    return timevec[index_range.end+index+1].send(model.time_convert) if index < 0
    timevec[index+offset] ? timevec[index+offset].send(model.time_convert) : nil
  end

  #
  # returns the length of this timeseries. Note that this is the "gross" length, taking into account
  # any pre or post bufferes
  #
  def length
    timevec.length
  end

  #
  # Returns he object that stored the last TA result set
  #
  def memo
    derived_values.last
  end

  # FiXME don't know why this is here!!!!
  def extended_range?
    true
  end

  #
  # When a TA method is applied to a timeseries, we keep the results around for later, plus any meta-data
  #
  def memoize_result(ts, fcn, idx_range, options, results, graph_type=nil)
    status = results.shift
    outidx = results.shift
    pb = AnalResults.new(ts, fcn, ts.local_range, idx_range, options, outidx, graph_type, results)
    @derived_values << pb

    #FIXME overlap should be plotted on the same graph (the oposite of what is coded here)
    #FIXME whereas non-overlap should be plotted in separate graphs

    if graph_type == :overlap
      aggregate(symbol, pb, options.merge(:with => 'financebars')) if options[:plot_results]
    else
      with_function fcn  if options[:plot_results]
    end
    case options[:result]
    when nil    : raise ArgumentError, ':result of (:keys|:memo|:raw) required as an option'
    when :keys  : pb.keys
    when :memo  : pb
    when :raw   : results
    else        nil
    end
  end

  def update_from_snapshot
    raise TimeseriesException, "Snapshot is not at the end of the Timeseries" if timevec.last.to_day > Date.today
    if timevec.last.to_date == Date.today
      time_map[timevec.last] = nil
      pop_values()
      push_last_bar(false)
    else
      push_last_bar(true)
    end
  end

  def push_last_bar(append)
    bar = Snapshot.last_bar(ticker_id)
    time = bar.delete :time

    bar.keys.each do |key|
      value_hash[key].push(bar[key])
    end
    if model.time_class == Date
      timevec.push(time.utc.midnight)
      value_hash[:date].push(time.utc.midnight)
    else
      timevec.push(time)
      value_hash[:start_time].push(time)
    end
    time_map[timevec[-1]] = timevec.length-1
    if append
      @local_range = local_range.begin..(time.to_date)
      @end_index = time2index(local_range.end, -1)
      @index_range = (index_range.begin)...end_index
    end
  end

  def pop_values()
    value_hash.values.each { |val_vec| val_vec.pop }
  end

  #
  # One of the ways of computing price
  #
  def avg_price
    (open+close+high+low).scale(0.25)
  end

  def calc_prebuffer()
    pbopt = options[:pre_buffer]
    if pbopt == :ema
      raise ArgumentError, ":time_period must be specified if :pre_buffer => :ema" if options[:time_period].nil?
      3.45 * (options[:time_period]+1)
    elsif pbopt.is_a? Numeric
      pbopt.to_i
    elsif pbopt == true # FIXME should have list of possible talib fcns and select the max of the loopback functions
      PRECALC_BARS
    else
      0
    end
  end

  #
  # Find a previous result set by its name and meta-data
  #
  def find_memo(fcn_symbol, time_range=nil, options={})
    fcn = fcn_symbol.to_sym
    derived_values.reverse.find do |pb|
      pb.function == fcn_symbol &&
        (time_range.nil? || pb.time_range == time_range) &&
        (options.empty? || pb.options == options)
    end
  end

  def add_methods_for_attributes(attrs)
    attrs.each do |attr|
      instance_eval("def #{attr}(); @value_hash['#{attr}'.to_sym].to_gv; end")
      instance_eval("def #{attr}_before_cast(); @value_hash['#{attr}'.to_sym]; end")
    end
  end

#  def method_missing(meth, *args)
#    model.content_columns.map(&:name).include? meth
#  end

  def initialize_state
    @value_hash, @time_map = {}, {}
    @derived_values,  @attrs = [], []
    @timevec = []
    @utc_offset = Time.now.utc_offset
    @enum_index = 0
  end
end


def ts(symbol, local_range, seconds, options={})
  options.reverse_merge! :populate => true
  $ts = Timeseries.new(symbol, local_range, seconds, options)
  nil
end

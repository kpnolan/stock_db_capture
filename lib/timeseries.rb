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

class Timeseries

  include Plot
  include TechnicalAnalysis
  include UserAnalysis
  include CompositeAnalysis
  include ResultAnalysis
  include CsvDumper
  include Enumerable

  TRADING_PERIOD = 6.hours + 30.minutes
  PRECALC_BARS = 120

  DEFAULT_OPTIONS = { DailyBar => { :sample_resolution => [ 1.day ], :bars_per_day => 1  },
                      IntraDayBar => { :sample_resolution => [ 30.minutes ],  :bars_per_day => 13 } }

  attr_accessor :symbol, :ticker_id, :model, :value_hash, :enum_index, :enum_attrs, :model_attrs, :bars_per_day
  attr_accessor :begin_time, :end_time, :utc_offset, :resolution
  attr_accessor :attrs, :derived_values, :output_offset, :plot_results, :stride
  attr_accessor :timevec, :time_map, :local_range, :price, :index_range

  def initialize(symbol_or_id, local_range, time_resolution=1.day, options={})
    options.reverse_merge! :price => :default, :plot_results => true, :pre_buffer => true, :populate => true, :post_buffer => false
    initialize_state()
    @ticker_id = (symbol_or_id.is_a? Fixnum) ? Ticker.find(symbol_or_id).id : Ticker.lookup(symbol_or_id).id
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
    @bars_per_day = model_attrs[:bars_per_day]
    @attrs = model.content_columns.map { |c| c.name.to_sym }
    set_enum_attrs(attrs)
    @stride = options[:stride].nil? ? 1 : options[:stride]
    pre_offset = options[:pre_buffer] == true ? 120 : options[:pre_buffer].is_a?(Fixnum) ? options[:pre_buffer] : 0
    post_offset = options[:post_buffer] == true ? 120 : options[:post_buffer].is_a?(Fixnum) ? options[:post_buffer] : 0
    debugger
    @begin_time = offset_date(@local_range.begin, pre_offset, -1)
    @end_time = (od = offset_date(@local_range.end, post_offset, 1)) > Time.now ? Time.now : od
    @plot_results = options[:plot_results]
    options.reverse_merge!(DEFAULT_OPTIONS[model])
    options[:populate] ? repopulate({}) : init_timevec
    add_methods_for_attributes(value_hash.keys)
    set_price(options[:price])
  end

  #
  # Parse a date/time string with the nominal format (see 2nd arg to strptime)
  # returning a time have the local timezone
  #
  def self.parse_time(date_time_str)
    d = Date._strptime(date_time_str, "%m-%d-%Y %H:%M")
    Time.utc(d[:year], d[:mon], d[:mday], d[:hour], d[:min],
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
  # as the beginning of the actual timeseries (minus any pre-buffering). We pre-buffer 120
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
  def set_enum_attrs(attrs)
    raise ArgumentError, "attrs is not a proper subset of available values" unless attrs.all? { |attr|self.attrs.include? attr }
    self.enum_attrs = attrs
  end

  #
  # The is the "each" mentioned above. Notice that it only yields the preselected enum variables
  #
  def each
    @timevec.each_with_index { |time,i | yield(values_at(i, enum_attrs)) }
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
    vals.map { |v| value_hash[v][index] }
  end

  #
  # This is like all() only it allows for the specification of parameters
  #
  def multi_calc(fcn_vec, options={})
    return nil if fcn_vec.empty?
    fcn_vec.each { |function| self.send(function, options.merge(:noplot => true)) }
    aggregate_all(symbol, options.merge(:multiplot => true, :with => 'financebars'))
    clear_results
  end


  def multi_fopt(fopt_vec, options={})
    fopt_vec.each do |ary|
      raise ArgumentError, "Expecting an Array of [:function, {options}]" unless ary.is_a? Array
      self.send(ary.first, ary.last.merge(:noplot => true))
    end
    aggregate_all(symbol, options.merge(:multiplot => true, :with => 'financebars'))
    clear_results
  end

  def find_result(fcn, options={})
    values = derived_values.reverse.select { |pb| pb.match(fcn, options) }
    return values.first unless values.empty?
  end

  def clear_results
    self.derived_values = []
  end

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

  def set_price(expression = :default)
    self.price = case
                 when expression == :default      : close
                 when expression == :average      : (high+low).scale(0.5)
                 when expression == :all          : (open+close+high+low).scale(0.25)
                 when expression.is_a?(Symbol)    : send(expression)
                 when expression.is_a?(String)    : instance_eval(expression)
                 end
  end

  def select_by_resolution(resolution)
    DEFAULT_OPTIONS.each_pair do |key, value|
      return key, value if value[:sample_resolution].include? resolution
    end
    raise ArgumentError, "A sampling resolution of #{resolution} is not available"
  end

  def offset_date(ref_date, pre_offset, dir)
    trading_days = ((1.day / bars_per_day ) * pre_offset) /1.day
    trading_days_from(ref_date, trading_days, dir).last.to_time.utc.midnight
  end

  def init_timevec
    value_hash[model.time_col.to_sym] = model.time_vector(symbol, begin_time, end_time)
    compute_timestamps
  end

  def repopulate(options)
    @value_hash = model.general_vectors(symbol, attrs, begin_time, end_time)
    raise Exception, "No values where return from #{model.to_s.tableize} for #{symbol} #{begin_time.to_s(:db)} through #{end_time.to_s(:db)}" if value_hash.empty?
    compute_timestamps
  end

#  private

  def apply_options(options)
    options.keys.each do |key|
      self.send("#{key}=", options[key]) if respond_to? key
    end
  end

  def compute_timestamps
    if model.time_class == Date
      self.timevec = value_hash[model.time_col.to_sym].collect { |dt| dt.to_time.utc.to_time.midnight }
    else
      self.timevec = value_hash[model.time_col.to_sym].collect { |twz| twz.time }
    end
    self.timevec.each_with_index { |time, idx| self.time_map[time] = idx }
  end

  def minimal_samples(lookback_fun, *args)
    lookback_fun ? Talib.send(lookback_fun, *args) : args.sum
  end

  # FIXME outidx is unique to function and params and so much be indexed as such!!!!!!!!!!!!!!!!!!

  def calc_indexes(loopback_fun, *args)
    begin_time = local_range.begin.utc.midnight
    end_time = local_range.end.utc.midnight
    begin_index = time2index(begin_time, 1)
    end_index = time2index(end_time, 1)
    self.output_offset = begin_index >= (ms = minimal_samples(loopback_fun, *args)) ? 0 : ms - begin_index
    raise ArgumentError, "Only subset of Date Range available, pre-buffer at least #{output_offset} more trading days" if output_offset > 0
    @index_range = begin_index..end_index
  end

  def time2index(time, direction, raise_on_range_error=true)
    case
    when model.time_class == Date : time2index_days(time, direction, raise_on_range_error=true)
    when model.time_class == Time : time2index_time(time, direction, raise_on_range_error=true)
    else debugger
    end
  end

  def time2index_days(time, direction, raise_on_range_error)
    adj_time = time.to_time.utc.midnight
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
    raise TimeseriesException.new, "#{time} is not contained within the DB" if time_map[adj_time].nil?
    return time_map[adj_time]
  end

  def time2index_time(time, direction, raise_on_range_error=true)
    adj_time = time + 9.5.hours.to_i if time.at_midnight
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
    raise TimeseriesException.new, "#{time} is not contained within the DB" if time_map[adj_time].nil?
    return time_map[adj_time]
  end

  def value_at(index, slot)
    send(slot)[index]
  end

  def times_for(indexes)
    indexes.map { |index| index2time(index) }
  end

  def index2time(index, offset=0)
    return nil if index >= timevec.length
    timevec[index+offset] ? timevec[index+offset].send(model.time_convert) : nil
  end

  def length
    timevec.length
  end

  def memo
    derived_values.last
  end

  def extended_range?
    true
  end

  def memoize_result(ts, fcn, idx_range, options, results, graph_type=nil)
    status = results.shift
    outidx = results.shift
    pb = AnalResults.new(ts, fcn, ts.local_range, idx_range, options, outidx, graph_type, results)
    self.derived_values << pb

    #FIXME overlap should be plotted on the same graph (the oposite of what is coded here)
    #FIXME whereas non-overlap should be plotted in separate graphs

    if graph_type == :overlap
      aggregate(symbol, pb, options.merge(:with => 'financebars')) unless options[:noplot]
    else
      with_function fcn  unless options[:noplot]
    end
    case options[:result]
    when nil    : nil
    when :keys  : pb.keys
    when :memo  : pb
    when :raw   : results
    else        nil
    end
  end

  def avg_price
    (open+close+high+low).scale(0.25)
  end

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
      instance_eval("def #{attr}(); self.value_hash['#{attr}'.to_sym].to_gv; end")
      instance_eval("def #{attr}_before_cast(); self.value_hash['#{attr}'.to_sym]; end")
    end
  end

#  def method_missing(meth, *args)
#    model.content_columns.map(&:name).include? meth
#  end

  def initialize_state
    self.value_hash, self.time_map = {}, {}
    self.derived_values,  self.attrs = [], []
    self.timevec = []
    self.utc_offset = Time.now.utc_offset
    self.enum_index = 0
  end
end


def ts(symbol, local_range, seconds, options={})
  options.reverse_merge! :populate => true
  $ts = Timeseries.new(symbol, local_range, seconds, options)
  nil
end

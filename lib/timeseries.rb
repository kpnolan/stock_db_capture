# Class: Timeseries
#
# This is the work-horse class for the entire reset of the system.
# Every sample of bar data is eventually converted to a timeseries
# upon with every indicator must operate.
# An element of a Timeseries is an entire bar (OHLCV) + logr (log return).
# A Timerseries can have gaps and can have multiple resolutions, e.g. daily, intraday(5,6,15,30)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'task/rpctypes'
require 'date'
require 'missing_bar_exception'
require 'technical_analysis'
require 'user_analysis'
require 'gnuplot'
require 'composite_analysis'
require 'result_analysis'
require 'csv_dumper'
require  'strategies/base'
require 'trading/strategies'
require 'ts_persistence'
require 'trading_calendar'
require 'anal_results'

class Time
  def bod?; hour == 6 && min == 30;end
  def eod?; hour == 13 && min == 30; end
  def in_trade?; hour >= 6 && hour <= 13; end
end

class Timeseries

  class TimeMap

    attr_reader :options, :first_index, :last_index,  :begin_time, :end_time, :timevec, :missing_ranges

    extend TradingCalendar

    def initialize(begin_time, end_time, timevec, options={ })
      @options = options.reverse_merge :missing_bar_error => :report
      @begin_time = begin_time
      @end_time = end_time
      @first_index = TimeMap.time2index(begin_time)
      @last_index = TimeMap.time2index(end_time, -1)
      @timevec = timevec
      @missing_ranges = []
      breakpoint if timevec.nil?
      raise ArgumentError, "Time Vecotor is wrong type: #{timevec.first.class}, does not act like time" unless !timevec.empty? && timevec.first.acts_like_time?
      missing_bar_proc = @options[:missing_bar_proc]
      if timevec.length <  last_index - first_index + 1
        case options[:missing_bar_error]
        when :report then report_missing_bars(missing_bars())
        when :ignore then save_ranges(missing_bars())
        else
          raise ArgumentError, ':missing_bar_error can be :report or :ignore'
        end
      end
    end

    def is_proxy?
      false
    end

    def index2time(index)
      return TimeMap.index2time(first_index+index) if index < timevec.length
      raise ArgumentError, "index [#{index}] is ouside of the range of bars, the maximum of which is #{timevec.length-1}"
    end

    def time2index(date_or_time, round=0)
      time = date_or_time.to_time
      time = time.to_time.localtime.change(:hour => 6, :min => 30)
      abs_index = TimeMap.time2index(time, round)
      abs_index - first_index
    end

    def save_ranges(mbs)
      ranges = TimeMap.to_ranges(mbs)
      @missing_ranges = ranges.map do |time_or_range|
        time_or_range.is_a?(Time) ? time_or_range..time_or_range : time_or_range
      end
    end

    def report_missing_bars(mbs)
      ranges = TimeMap.to_ranges(mbs)
      raise MissingBarException, "Missing bars from #{ranges.map{ |r| TimeMap.pretty_range(r)}.join(', ')} (#{mbs.length} trading days)"
    end

    def missing_bars()
      timevec_as_seconds = timevec.map(&:to_i)
      missing_bars_as_seconds = expected_bars_as_seconds - timevec_as_seconds
      missing_bars_as_seconds.map { |secs| Time.at(secs) }
    end

    def expected_bars_as_seconds()
      (first_index..last_index).to_a.map { |index| TimeMap.index2time(index).to_i }
    end

    def TimeMap.pretty_range(range)
      case range
        when Range
        begin_str = range.begin.to_formatted_s(:ymd)
        end_str = range.end.to_formatted_s(:ymd)
        "#{begin_str}..#{end_str}"
      else
        range.to_formatted_s(:ymd)
      end
    end
  end

  include Plot
  include TechnicalAnalysis
  include UserAnalysis
  include CompositeAnalysis
  include ResultAnalysis
  include CsvDumper
  include Enumerable
  include Strategies::Base
  include Trading::Strategies
  include TsPersistence
  extend TradingCalendar

  TRADING_PERIOD = 6.hours + 30.minutes
  PRECALC_BARS = 50
  POSTCALC_BARS = 30
  DEFAULT_OPTIONS = {
    DailyBar =>     { :sample_resolution => 1.day , :non_attrs => [ :logr ]   },
    IntraDayBar =>  { :sample_resolution => 30.minutes, :non_attrs => [ :period, :delta, :seq ] },
    Snapshot =>     { :sample_resolution => 1.minute, :non_attrs => [ :secmid ] } }

  attr_reader :symbol, :ticker_id, :model, :value_hash, :result_hash, :enum_index, :enum_attrs, :model_attrs, :bars_per_day
  attr_reader :begin_time, :end_time, :pre_offset, :post_offset, :utc_offset, :resolution, :options
  attr_reader :attrs, :derived_values, :output_offset, :stride, :stride_offset, :frozen
  attr_reader :timevec, :time_map, :local_range, :price, :index_range, :begin_index, :end_index
  attr_reader :expected_bar_count
  attr_accessor :logger
  cattr_accessor :global_logger

  def initialize(symbol_or_id, local_range, time_resolution=1.day, options={})
    @options = options.reverse_merge :price => :default, :pre_buffer => 0, :populate => false, :post_buffer => 0, :plot_results => false, :missing_bar_error => :report, :max_date => Date.today - 1
    initialize_state()
    debugger if local_range.begin > local_range.end
    @ticker_id = Ticker.resolve_id(symbol_or_id)
    raise ArgumentError, "Excpecting ticker symbol or ticker id as first argument. Neither could be found" if ticker_id.nil?
    @symbol = Ticker.find(ticker_id, :select => :symbol).symbol
    #
    # FIXME !!! We need a way of trapping ranges who go beyond recorded bars and if we allow this, the adjustments have to propigate throughout the
    # entire time mapping system (which they are currently NOT doing, resulting in surprises at the boundary conditions
    #
    if local_range.is_a? Range
      if local_range.begin.is_a?(Date) && local_range.end.is_a?(Date)
        @local_range = local_range.begin.to_time.change(:hour => 6, :min => 30)..local_range.end.to_time.change(:hour => 6, :min => 30)
      elsif local_range.begin.acts_like_time? && local_range.end.acts_like_time?
        @local_range = local_range.begin...local_range.end
      else
        raise ArgumentError, "local_range must be a Date, a Range of Dates or Times, or String"
      end
    else
      if local_range.is_a?(Date)
        @local_range = local_range.to_time..(local_range.to_time + 1.day)
      elsif local_range.is_a?(String)
        @local_range = parse_local_string(local_range)
      else
        raise ArgumentError, "local_range must be a Date, a Range of Dates or Times, or String"
      end
    end
    @model, @model_attrs = select_by_resolution(time_resolution)
    @resolution = time_resolution
    @bars_per_day =  resolution == 1.day ? 1 : TRADING_PERIOD / resolution
    @attrs = model.content_columns.map { |c| c.name.to_sym } - DEFAULT_OPTIONS[model][:non_attrs]
    set_enum_attrs(attrs)
    @stride = options[:stride].nil? ? 1 :  options[:stride]
    @stride_offset = options[:stride_offset].nil? ? 0 : options[:stride_offset]
    @logger = options[:logger]
    raise ArgumentError, "Stride offset with no stride makes no sense also stride_offset must be < stride" if stride && stride_offset >= stride
    self.options.reverse_merge!(DEFAULT_OPTIONS[model])
    remember_params(:none)
    populate() if self.options[:populate]
  end

  def Timeseries.attach_logger(logger)
    @@global_logger = logger
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

  def to_proxy
    params = options.dup
    params.delete(:logger)
    params[:sample_resolution] = params[:sample_resolution].to_i if params[:sample_resolution]
    Task::RPCTypes::TimeseriesProxy.new(ticker_id, local_range, resolution, params)
  end
  #
  # Since we don't keep a reference to tickers around, deref the id and
  # return the associated Ticker
  #
  def ticker
    Ticker.find ticker_id
  end

  def year()
    local_range.begin.year
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
  alias result_offset outidx

  def adj_result_index(index)
    result_offset + index
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
  #  # returns a *hash* of values the keys of which are *attrs* for the index specified
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
    vals
  end
  #
  # Need to define a max_exit_date which we will assume is the end of the local range
  #
  def max_exit_date
    local_range.end
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
  # Return and array of ranges for the misssing bars in the timesers
  #
  def missing_ranges()
    return [] if @time_map.nil?
    @time_map.missing_ranges()
  end

  #
  # Clears the objects retaining the results of prior TA calles
  #
  def clear_results
    @derived_values = []
  end

  def result_keys
    derived_values.map do |pb|
      { pb.function => pb.names }
    end
  end

  #
  # Returns the results of a prior TA call, takes a symbol or pair [ :fcn, :result_name ]
  #
  def vector_for(sym_or_pair)
    derived_values.each do |memo|
      case
      when sym_or_pair.is_a?(Symbol) &&
           memo.result_hash.has_key?(sym_or_pair)                       then return memo.result_hash[sym_or_pair]
      when sym_or_pair.is_a?(Array) && sym_or_pair.first == memo.function &&
           memo.result_hash.hash_key?(sym_or_pair.second)               then return memo.result_hash[sym_or_pair.second]
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
             when expression == :default      then close
             when expression == :average      then (high+low).scale(0.5)
             when expression == :all          then (open+close+high+low).scale(0.25)
             when expression.is_a?(Symbol)    then send(expression)
             when expression.is_a?(String)    then instance_eval(expression)
             end
  end

  #
  # Selects the DB model containing the resolution (1.day, 30.minutes, 5.minute) of the bars
  #
  def select_by_resolution(resolution)
    DEFAULT_OPTIONS.each_pair do |key, value|
      return key, value if value[:sample_resolution] == resolution
    end
    raise ArgumentError, "A sampling resolution of #{resolution} is not available"
  end

  #
  # Compute the calendar date to be given to the DB to grab the selected data range plus any pre-buffering
  #
  def offset_date(ref_date, offset)
    return ref_date if offset.zero?
    trading_day_count = ((1.day / bars_per_day ) * offset) /1.day
    new_date = Timeseries.trading_date_from(ref_date, trading_day_count)
    return new_date if new_date.is_a? Date
    new_date = new_date.change(:hour => 6, :min => 30) unless new_date.zone.first == 'E'  #Eastern Time
    new_date
  end

  #
  # initializes the time vector for this time series
  #
  def init_timevec
    value_hash[:bartime] ||= model.time_vector(symbol, begin_time, end_time)
    compute_timestamps(begin_time, end_time)
  end

  #
  # Maps the start and end dates to indexes gotten from the timevec map
  #
  def map_local_range()
    @begin_index = time2index(local_range.begin)
    @end_index = time2index(local_range.end, -1)  # FIXME this gives an unreachable index causing Exceptions down the line...
    @index_range = begin_index..end_index
    debugger if end_index < begin_index
    index_range
  end
  #
  # compute the local range w/o side-effects
  #
  def compute_local_range()
    begin_index = time2index(local_range.begin)
    end_index = time2index(local_range.end, -1)  # FIXME this gives an unreachable index causing Exceptions down the line...
    begin_index..end_index
  end
  #
  # reset the date range for this timeseries, fetching more data if necessary
  #
  def reset_local_range(start_date, end_date)
    if start_date.is_a?(Date) && end_date.is_a?(Date)
        @local_range = start_date.to_time.change(:hour => 6, :min => 30)..end_date.to_time.change(:hour => 6, :min => 30)
    elsif local_range.begin.acts_like_time? && local_range.end.acts_like_time?
      @local_range = start_date...end_date
    else
      raise ArgumentError, "args must either be dates or times"
    end
    if local_range.begin < begin_time or local_range.end > end_time
      logger.info "reloading Timeseries #{symbol} #{local_range.begin.to_formatted_s(:ymd)} < #{begin_time.to_formatted_s(:ymd)} *OR* "+
                  "#{local_range.end.to_formatted_s(:ymd)} > #{end_time.to_formatted_s(:ymd)}"
      populate()
      puts "repopulating timeseries on reset_local_range #{start_date}..#{end_date}"
    else
      map_local_range()
    end
  end
  #
  # Expand or contact the indexes based upon the requirements of any technical indicator
  # using this timeseries
  #
  def calculate_fill_indexes(pre_buffer)
    @pre_offset = pre_buffer.nil? ? options[:pre_buffer] : pre_buffer
    @post_offset = options[:post_buffer]
    @begin_time = offset_date(local_range.begin, -pre_offset)
    @end_time = offset_date(local_range.end, post_offset)
    if @end_time > Date.today
      ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => ticker_id } )
      @end_time = ticker_max.localtime
    end
    @expected_bar_count =  Timeseries.trading_day_count(begin_time, end_time) * bars_per_day
  end
  #
  # Populates the timeseries with the results stored in the DB. This is resolution agnostic.
  # If the Timeseries whas specified with a stride, populated Timeseries with just the values
  # according to the stride and stride offset.
  #
  def populate(pre_offset=nil)
    if pre_offset.nil?
      calculate_fill_indexes(nil)
      raw_populate()
    elsif @pre_offset && pre_offset == @pre_offset           # Nothing need to change -- new data set bounded the same
      return self.index_range
    elsif @pre_offset && pre_offset < @pre_offset
      map_local_range()
    else
      calculate_fill_indexes(pre_offset)
      raw_populate()
    end
  end
  #
  # Does the nitty gritty of populating the timeseries
  #
  def raw_populate()
    @value_hash = model.general_vectors(ticker_id, attrs, begin_time, end_time)

    raise DelistedStockException.new(symbol) if @value_hash.empty?
    @populated = true
    push_bar(@last_bar) if @last_bar
    compute_timestamps(begin_time, end_time)
    missing_bar_count = expected_bar_count - timevec.length
    raise TimeseriesException, "No values where returned from #{model.to_s.tableize} for #{symbol} " +
      "#{begin_time.to_s(:db)} through #{end_time.to_s(:db)}" if value_hash.empty?
    # We should only get here if we are not accessing DailyBars, otherwise that would have been caught earlier
    raise TimeseriesException, "Missing #{missing_bar_count} bars for #{symbol}" if missing_bar_count > 0 unless options[:missing_bar_error] == :ignore

    if stride > 1
      new_hash = { }
      value_hash.each_pair do |k,v|
        vec = []
        v.each_with_index { |e,i| vec << e if i % stride == stride_offset }
        new_hash[k] = vec
      end
      @value_hash = new_hash
    end
    unless respond_to? :close
      add_methods_for_attributes(value_hash.keys)
      set_price(self.options[:price])
    end
    map_local_range()
  end

  def populated?
    @populated
  end

  def depopulate()
    initilze_state()
    @pre_offset = -1
    remember_params(:none)
    @populated = false
  end

#  private

  def error(msg)
    logger = self.logger || Timeseries.global_logger
    logger.error(msg)
  end

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
  def compute_timestamps(begin_time, end_time)
    @timevec = value_hash[:bartime]
    if model == DailyBar
      begin
        @time_map = TimeMap.new(begin_time, end_time, timevec, :missing_bar_error => options[:missing_bar_error])
      rescue TimeseriesException => e
        raise TimeseriesException, "#{e.message} for #{symbol}"
      end
    else
      timevec.each_with_index { |time, idx| @time_map[time.to_i] = idx }
    end
  end

  def params_changed?(lookback_fcn, *args)
    lookback_fcn != @lookback_fcn || args != @lookback_args
  end

  def remember_params(lookback_fcn, *args)
    @lookback_fcn = lookback_fcn
    @lookback_args = args
  end

  def today
    index_range.begin - pre_offset
  end

  # FIXME outidx is unique to function and params and so much be indexed as such!!!!!!!!!!!!!!!!!!

  def calc_indexes(lookback_fcn=nil, *args)
    return index_range if frozen
    ms = pre_offset = calc_prefetch(lookback_fcn, *args)
    #pre_offset = params_changed?(lookback_fcn, *args) ? calc_prefetch(lookback_fcn, *args) : @pre_offset
    index_range = populate(pre_offset)
    begin_index = index_range.begin
    @output_offset = begin_index >= ms ? 0 : ms - begin_index
    # commented out since minimal samples has already been computed
    #@output_offset = begin_index >= (ms = Timeseries.minimal_samples(lookback_fcn, *args)) ? 0 : ms - begin_index
    if @output_offset > 0
      debugger
    end
    raise ArgumentError, "Only subset of Date Range available for #{symbol}, pre-buffer at least #{@output_offset} more bars" if @output_offset > 0
    remember_params(lookback_fcn, *args)
    return index_range
  end
  #
  # Maps the time or data to the specific index in the vector for the sample associated with that date/time
  #
  def time2index(time, round=0)
    if model == DailyBar
      time_map.time2index(time, round)
    elsif (index = time_map[time.to_i]).nil?
      raise ArgumentError, "Cannot find index matching rgw time: #{time}"
    else
      index
    end
  end
  #
  # Return the date and closing price for a time series index
  #
  def closing_values_at(index)
    return index2time(index), value_at(index, :close)
  end

  # Persist the contents of a set of results to an IndicatorValue table
  def persist_results(trigger, position, *result_names)
    result_names.each do |name|
      indicator_id = Indicator.lookup(name).id
      result_vec = result_hash[name]
      result_vec.each_index do |index|
        IndicatorValue.record_element(trigger, indicator_id, position, index2time(index+result_offset), result_vec[index])
      end
    end
  end
  #
  # Returns a the value at an index location of a bar or result #FIXME this function is duplicated elswhere
  #
  def values_at(index, *slots)
    slots.map { |s| value_hash[s][index]}
  end

  def value_hash_at(index, *slots)
    slots.inject({}) { |h, s| h[s] = value_hash[s][index]; h}
  end
  #
  # Return the result element corresponding to the input vector index *index*.
  # FIXME We really need a better way of delaying with two index values, e.g. one for results and one for bar values. We need to unify them at some
  # point or (gag) invent an offseted array class which tracks offsets and does the right thing.
  #
 def result_at(time_or_index, slot)
   begin
     case time_or_index
     when Time       then result_hash[slot][time2index(time_or_index)-result_offset]
     when Numeric    then result_hash[slot][time_or_index-result_offset]
     when NilClass   then nil
     else
       raise ArgumentError, "first arg must be a Time or a Fixnum, instead was #{time_or_index}"
     end
   rescue Exception => e
     logger.error "can't find index #{time_or_index} @ slot: #{slot}: #{e.to_s}" if logger
     return -0.0
   end
 end

 def value_at(time_or_index, slot)
    case time_or_index
    when Time       then value_hash[slot][time2index(time_or_index)]
    when Numeric    then value_hash[slot][time_or_index]
    else
      raise ArgumentError, "first arg must be a Time or a Fixnum, instead was #{time_or_index}"
    end
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
  def index2time(index)
    case
    when index.nil? then nil
    when model == DailyBar then time_map.index2time(index)
    when index > 0 && index < timevec.length then timevec[index]
    when index < 0 then  raise ArgumentError, "index [#(index}] is negative"
      raise ArgumentError, "index [#(index}] is ouside of the range of bars, the maximum of which is #{timevec.length-1}"
    end
  end
  #
  #
  #
  def rindex2time(index)
    index2time(index + result_offset)
  end
  #
  # returns the length of this timeseries. Note that this is the "net" length
  #
  def length
    timevec[index_range].length
  end

  #
  # returns the length of this timeseries. Note that this is the "gross" length, taking into account
  # any pre or post bufferes
  #
  def len
    timevec.length
  end

  #
  # Returns he object that stored the last TA result set
  #
  def memo
    derived_values.last
  end

  def log_result(symbol_or_string)
    case symbol_or_string
    when Symbol then
      result_vec = result_for(symbol_or_string)
      timvec = self.timevec[index_range]
      timevec.each_with_index do |time, i|
        logger.info("#{symbol} #{time.to_formatted_s(:ymd)}: #{format('%2.2f', result_vec[i])}")
      end
    when String then logger.info("#{symbol}: #{symbol_or_string}")
    end
  end

  #
  # When a TA method is applied to a timeseries, we keep the results around for later, plus any meta-data
  #
  def memoize_result(ts, fcn, idx_range, options, results, graph_type=nil)
    status = results.shift
    outidx = results.shift

    pb = AnalResults.new(ts, fcn, ts.local_range, idx_range, options, outidx, graph_type, results)
    @derived_values << pb
    result_hash.merge! pb.result_hash

    #FIXME overlap should be plotted on the same graph (the oposite of what is coded here)
    #FIXME whereas non-overlap should be plotted in separate graphs

    if options[:plot_results]
      if graph_type == :overlap
        aggregate(symbol, pb, options.merge(:with => 'financebars'))
      else
        with_function fcn
      end
    end

    @reserved_options ||= %w{ keys memo gv raw first array third, last csv series}.inject({}) { |h, k| h[k.to_sym] = true; h }
    if @reserved_options[options[:result]]
      results = case options[:result]
                when :keys  then pb.keys
                when :memo  then pb
                when :raw   then results
                when :first then results.first
                when :last  then results.first && results.first.last
                when :array then results.first.to_a
                when :gv    then results.first
                when :third then results.third
                when :csv   then pb.generate_csv()
                when :series then generate_series(results)
                end
    elsif options[:result].is_a?(Array)
      raise TimeseriesException, "Invald result key #{@key}" unless options[:result].all? { |sym| @key = sym; pb.result_hash.has_key?(sym) }
      options[:result].map { |sym| pb.result_hash[sym] }
    elsif result_hash.keys.include? options[:result]
      result_hash[options[:result]]
    elsif options[:result].nil?
      results.first && results.first.last
    else
      raise ArgumentError, "invalid value for :result => #{options[:result]}"
    end
  end

  def generate_series(results)
    timevec[index_range].zip(results.first.to_a).each do |pair|
      puts "#{pair.first.to_formatted_s(:ymd)}  #{pair.second}"
    end
    nil
  end

  def update_last_bar(bar)
    puts "update lb: #{populated? ? 'true' : 'false'}"
    return @last_bar = bar unless populated?
    pop_values() if timevec.last.to_date == Date.today
    push_bar(bar)
    compute_timestamps(value_hash[:bartime].first, value_hash[:bartime].last)
    @local_range = local_range.begin..timevec.last
    map_local_range(true)
    @frozen = true
  end

  def push_bar(bar)
    bar = bar.dup
    time = bar.delete :time

    bar.keys.each do |key|
      value_hash[key].push(bar[key])
    end
    if model.time_class == Date
      value_hash[:bartime].push(time.localtime.change(:hour => 6, :min => 30))
    else
      value_hash[:bartime].push(time)
    end
  end

  def last_close()
    value_hash[:close][end_index]
  end

  #
  # Pop the last value from each one of the value vectors stored in the value hash
  #
  def pop_values()
    value_hash.values.each { |val_vec| val_vec.pop }
  end

  def ci
    @current_indicator
  end

  #
  # One of the ways of computing price
  #
  def avg_price
    (open+close+high+low).scale(0.25)
  end

  def calc_prefetch(lookback_fcn, *args)
    pbopt = options[:pre_buffer]
    if lookback_fcn
      @current_indicator = Timeseries.base_indicator(lookback_fcn)
      Timeseries.indicator_prefetch(@current_indicator, *args)
    elsif lookback_fcn.nil? && ! args.empty?
      args.sum
    elsif pbopt.is_a?(Numeric)
      Timeseries.set_unstable_period(:all, pbopt)
      pbopt
    elsif pbopt == :default
      Timeseries.set_unstable_period(:all, PRECALC_BARS)
      Timeseries.get_unstable_period(:all)
    else
      Timeseries.set_unstable_period(:all, 0)
      Timeseries.get_unstable_period(:all)
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
    @value_hash, @result_hash = {}, {}
    @derived_values,  @attrs = [], []
    @timevec = []
    @utc_offset = Time.now.utc_offset
    @enum_index = 0
  end
  #
  # Class Methods
  #
  class << self
    #
    # Parse a date/time string with the nominal format (see 2nd arg to strptime)
    # returning a time have the local timezone
    #
    def parse_time(date_time_str, fmt="%m/%d/%Y %H:%M")
      d = Date._strptime(date_time_str, fmt)
      Time.local(d[:year], d[:mon], d[:mday], d[:hour], d[:min],
                 d[:sec], d[:sec_fraction], d[:zone])
    end
  end
end

def ts(symbol, local_range, seconds=1.day, options={})
  $ts = Timeseries.new(symbol, local_range, seconds, options)
  nil
end

def sts(symbol, start_date, end_date, options={ })
  $ts = Timeseries.new(symbol, start_date.to_date..end_date.to_date, 1.day, options)
  nil
end

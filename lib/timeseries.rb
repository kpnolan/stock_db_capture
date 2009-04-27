class Timeseries

  include Plot
  include TechnicalAnalysis
  include UserAnalysis
  include CsvDumper

  TRADING_PERIOD = 6.hours + 30.minutes
  PRECALC_BARS = 252

  DEFAULT_OPTIONS = { DailyClose => { :attrs => [:date, :volume, :high, :low, :open, :close, :week, :r, :logr],
                                      :sample_period => [ 1.day ],
                                      :end_time => Time.now },
                     LiveQuote => { :attrs => [:last_trade, :volume ],
                                    :sample_period => [ 1.minute ],
                                    :end_time => Time.now },
                    Aggregate => {  :attrs => [ :date, :start, :volume, :high, :low, :open, :close, :r, :logr ],
                                    :sample_period => [ 5.minute, 10.minutes, 30.minutes ],
                                    :end_time => Time.now }

                                 }

  attr_accessor :symbol, :ticker_id, :source_model, :value_hash
  attr_accessor :start_time, :end_time, :num_points, :sample_period, :utc_offset
  attr_accessor :attrs, :derived_values, :output_offset, :plot_results
  attr_accessor :timevec, :xval_vec, :time_map, :index_map, :local_range, :price

  def initialize(symbol_or_id, local_range, time_resolution, options={})
    options.reverse_merge! :price => :default, :plot_results => true, :pre_buffer => true
    initialize_state()
    self.ticker_id = (symbol_or_id.is_a? Fixnum) ? Ticker.find(symbol_or_id) : Ticker.find_by_symbol(symbol_or_id.to_s)
    raise ArgumentError("Excpecting ticker symbol or ticker id as first argument. Neither could be found") if ticker_id.nil?
    self.symbol = Ticker.find(ticker_id).symbol
    self.source_model = select_by_resolution(time_resolution)
    bars_per_day = 1
    if source_model == Aggregate
      minutes = time_resolution / 60
      Aggregate.set_table_name("bar_#{minutes}s")
      bars_per_day = TRADING_PERIOD / time_resolution
      if options[:pre_buffer]
        day_offset = (PRECALC_BARS / bars_per_day) + 1
      else
        day_offset = (PRECALC_BARS / bars_per_day) + 1
      end
      self.start_time = (local_range.begin - day_offset.days).to_time
    elsif source_model == DailyClose
      self.start_time = (local_range.begin - 365.days).to_time
    else
      raise ArgumentError.new("Bar resolution cannot be retrieved")
    end
    self.plot_results = options[:plot_results]
    self.local_range = local_range
    options.reverse_merge!(DEFAULT_OPTIONS[source_model])
    apply_options(options)
    options[:populate] ? repopulate({}) : init_timevec
    add_methods_for_attributes(value_hash.keys)
    reset_price(options[:price])
  end

  def inspect
    super
  end

  def all(*args)
    multi_calc(args)
  end

  def multi_calc(fcn_vec, options={})
    return nil if fcn_vec.empty?
    fcn_vec.each { |function| self.send(function, options.merge(:noplot => true)) }
    aggregate_all(symbol, options.merge(:multiplot => true, :with => 'financebars'))
    clear_results
  end

  def multi_fopt(fopt_vec, options={})
    fopt_vec.each do |ary|
      raise ArgumentError.new("Expecting an Array of [:function, {options}]") unless ary.is_a? Array
      self.send(ary.first, ary.last.merge(:noplot => true))
    end
    aggregate_all(symbol, options.merge(:multiplot => true, :with => 'financebars'))
    clear_results
  end

  def find_result(fcn, options={})
    values = derived_values.select { |pb| pb.match(fcn, options) }
    return values.first unless values.empty?
  end

  def clear_results
    self.derived_values = []
  end

  def reset_price(expression = :default)
    if expression == :default
      self.price = (high+low).scale(0.5)
    elsif expression.is_a? Symbol
      self.price = send(expression)
    elsif expression.is_a? String
      self.price = instance_eval(expression)
    end
  end

  def select_by_resolution(period)
    DEFAULT_OPTIONS.each_pair do |key, value|
      return key if value[:sample_period].include? period
    end
    raise ArgumentError, "A sampling period/resolution of #{period} is not available"
  end

  def init_timevec
    value_hash[source_model.time_col.to_sym] = source_model.time_vector(symbol)
    compute_timestamps
  end

  def repopulate(options)
    apply_options unless options.empty?
    attrs = (timevec.empty? ? self.attrs | [ source_model.time_col.to_sym ] : self.attrs)
    if num_points > 0
      self.value_hash = source_model.simple_vectors(symbol, attrs, start_time, num_points)
    else
      self.value_hash = source_model.general_vectors(symbol, attrs, start_time, end_time)
    end
    compute_timestamps if time_map.empty?
  end

#  private

  def apply_options(options)
    options.keys.each do |key|
      self.send("#{key}=", options[key]) if respond_to? key
    end
  end

  def compute_timestamps
    if source_model.time_class == Date
      self.timevec = value_hash[source_model.time_col.to_sym].collect { |dt| dt.to_time.utc.to_time.midnight }
    else
      self.timevec = value_hash[source_model.time_col.to_sym].collect { |twz| twz.time }
    end
    self.timevec.each_with_index { |time, idx| self.time_map[time] = idx }
    self.index_map = time_map.invert
    self.xval_vec = source_model == Aggregate ? (1..timevec.length).to_a : timevec
  end

  def minimal_samples(lookback_fun, *args)
    lookback_fun ? Talib.send(lookback_fun, *args) : args.sum
  end

  def calc_indexes(loopback_fun, *args)
    if self.local_range.is_a? Date
      begin_time = self.local_range.to_time
      end_time = begin_time + 23.hours + 59.minutes
    else
      begin_time = self.local_range.begin
      end_time = self.local_range.end
    end
    begin_index = time2index(begin_time, -1)
    end_index = time2index(end_time, 1)
    self.output_offset = begin_index >= (ms = minimal_samples(loopback_fun, *args)) ? 0 : ms - begin_index
    return begin_index..end_index
  end

  def time2index(time, direction, raise_on_range_error=true)
    adj_time = time.to_time.utc.midnight
    if direction == -1
      raise TimeseriesException.new("#{symbol}: requested time is before recorded history: starting #{timevec.first}") if adj_time < timevec.first
      until time_map.include?(adj_time) || adj_time < timevec.first
        adj_time -= sample_period.first
      end
      raise TimeseriesException.new("#{time} is not contained within the DB") if time_map[adj_time].nil?
      time_map[adj_time]
    else # this is split into two loop to simplify the boundry test
      raise TimeseriesException.new("Requested time is after recorded history: ending #{timevec.last}") if adj_time > timevec.last
      until time_map.include?(adj_time) || adj_time > timevec.last
        adj_time += sample_period.first
      end
    end
    raise TimeseriesException.new("#{time} is not contained within the DB") if time_map[adj_time].nil?
    return time_map[adj_time]
  end

  def value_at(index, slot)
    send(slot)[index]
  end

  def times_for(indexes)
    indexes.map { |index| index2time(index) }
  end

  def index2time(index, offset=0)
    time = index_map[index+offset]
    time && time.send(source_model.time_convert)
  end

  def memoize_result(ts, fcn, idx_range, options, results, graph_type=nil)
    status = results.shift
    outidx = results.shift
    pb = ParamBlock.new(ts, fcn, ts.local_range, idx_range, options, outidx, graph_type, results)
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
    derived_values.find do |pb|
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
#    source_model.content_columns.map(&:name).include? meth
#  end

  def initialize_state
    self.value_hash, self.time_map, self.index_map = {}, {}, {}
    self.derived_values,  self.attrs = [], []
    self.timevec = []
    self.num_points, self.sample_period = 0, []
    self.utc_offset = Time.now.utc_offset
  end
end

class ParamBlock

  include ResultAnalysis

  attr_accessor :timeseries
  attr_accessor :function
  attr_accessor :time_range
  attr_accessor :index_range
  attr_accessor :options
  attr_accessor :outidx
  attr_accessor :vectors
  attr_accessor :graph_type
  attr_accessor :names
  attr_accessor :result_hash

  def initialize(ts, fcn, time_range, index_range, options, outidx, graph_type, results)
    self.function = fcn
    self.time_range = time_range
    self.index_range = index_range
    self.options = options
    self.outidx = outidx
    self.vectors = results
    self.graph_type = graph_type
    self.names = TALIB_META_INFO_DICTIONARY[fcn].stripped_output_names
    self.timeseries = ts
    self.result_hash = {}

    self.names.each_with_index { |name, idx| self.result_hash[name.to_sym] = vectors[idx] }
  end

  def vector_for(sym)
    if result_hash.has_key? sym
      result_hash[sym]
    elsif ts.methods.include? sym.to_s
      timeseries.send(sym)
    else
      raise ArgumentError.new("#{function}.#{sym} is not available")
    end
  end

  def match(fcn, options={})
    opts = self.options.dup
    opts.delete(:noplot)
    opts.delete(:input)
    return self if function == fcn && opts == options
  end

  def keys
    result_hash.keys
  end

  def to_ts
    timeseries
  end

  def decode(*syms)
    syms.collect do |sym|
      self.send(sym)
    end
  end
end

def ts(symbol, local_range, seconds, options={})
  options.reverse_merge! :populate => true
  $ts = Timeseries.new(symbol, local_range, seconds, options)
  nil
end

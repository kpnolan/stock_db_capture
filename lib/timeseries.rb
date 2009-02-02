class Timeseries

  include Plot
  include TechnicalAnalysis
  include UserAnalysis

  DEFAULT_OPTIONS = { DailyClose => { :attrs => [:date, :volume, :high, :low, :open, :close, :r, :logr],
                                      :sample_period => [ 1.day ],
                                      :start_time => Time.parse('2000-1-1'),
                                      :end_time => Time.now },
                     LiveQuote => { :attrs => [:last_trade, :volume, :change_points, :r, :logr],
                                    :sample_period => [ 1.minute ],
                                    :start_time => Time.parse('2000-1-1'),
                                    :end_time => Time.now },
                    Aggregate => {  :attrs => [ :date, :start, :volume, :high, :low, :open, :close, :r, :logr ],
                                    :sample_period => [ 5.minutes, 15.minutes, 30.minutes, 1.hour ],
                                    :start_time => Time.parse('2008-12-1'),
                                    :end_time => Time.now }

                                 }

  attr_accessor :symbol, :source_model, :value_hash, :time_interval
  attr_accessor :start_time, :end_time, :num_points, :sample_period, :utc_offset
  attr_accessor :attrs, :derived_values, :output_offset, :plot_results
  attr_accessor :timevec, :time_map, :index_map, :local_focus

  def initialize(symbol, time_resolution, options={})
    self.symbol = symbol
    self.source_model = select_by_resolution(time_resolution)
    self.plot_results = true
    initialize_state
    options.reverse_merge!(DEFAULT_OPTIONS[source_model])
    apply_options(options)
    options[:populate] ? repopulate({}) : init_timevec
    add_methods_for_attributes(value_hash.keys)
  end

  def inspect
    super
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
    elsif time_interval > 0
      self.value_hash = source_model.general_vectors_by_interval(symbol, attrs, start_time, time_interval)
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
    self.timevec = value_hash[source_model.time_col.to_sym].collect { |dt| dt.to_time.utc.to_time.midnight }
    self.timevec.each_with_index { |time, idx| self.time_map[time] = idx }
    self.index_map = time_map.invert
    nil
  end

  def minimal_samples(lookback_fun, *args)
    lookback_fun ? Talib.send(lookback_fun, *args) : 0
  end

  def calc_indexes(loopback_fun, time_range, *args)
    if time_range.is_a? Date
      begin_time = time_range.to_time
      end_time = begin_time + 23.hours + 59.minutes
    else
      begin_time = time_range.begin
      end_time = time_range.end
    end
    begin_index, fall_back = time2index(begin_time, -1)
    end_index, fall_fwd = time2index(end_time, 1)
    raise TimeseriesException.new if fall_back || fall_fwd
    self.output_offset = begin_index >= (ms = minimal_samples(loopback_fun, *args)) ? 0 : ms - begin_index
    return begin_index..end_index
  end

  def time2index(time, direction, raise_on_range_error=true)
    time = time.to_time.utc.midnight
    if direction == -1
      return 0 if time < timevec.first
      until time_map.include?(time) || time < timevec.first
        last_back_time = time
        time -= sample_period.first
      end
      return time_map[time].nil? ? [nil, last_back_time] : time_map[time]
    else # this is split into two loop to simplify the boundry test
      return timevec.length() -1 if time > timevec.last
      until time_map.include?(time) || time > timevec.last
        last_fwd_time = time
        time += sample_period.first
      end
    end
    return time_map[time].nil? ? [nil, last_fwd_time] : time_map[time]
  end

  def index2time(index)
    time = index_map[index]
    time && time.send(source_model.time_convert)
  end

  def memoize_result(fcn, time_range, idx_range, options, results, graph_type=nil)
    status = results.shift
    outidx = results.shift
    pb = ParamBlock.new(fcn, time_range, idx_range, options, outidx, graph_type, results)
    self.derived_values << pb

    if graph_type == :overlap
      aggregate(symbol, pb, options.merge(:with => 'financebars'))
    else
      with_function fcn
    end
    pb
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
    self.local_focus = nil
    self.derived_values,  self.attrs = [], []
    self.timevec = []
    self.time_interval, self.num_points, self.sample_period = 0, 0, []
    self.start_time, self.end_time = nil, nil
    self.utc_offset = Time.now.utc_offset
  end
end

class ParamBlock
  attr_accessor :function
  attr_accessor :time_range
  attr_accessor :index_range
  attr_accessor :options
  attr_accessor :outidx
  attr_accessor :vectors
  attr_accessor :graph_type
  attr_accessor :names

  def initialize(fcn, time_range, index_range, options, outidx, graph_type, results)
    self.function = fcn
    self.time_range = time_range
    self.index_range = index_range
    self.options = options
    self.outidx = outidx
    self.vectors = results
    self.graph_type = graph_type
    self.names = TALIB_META_INFO_DICTIONARY[fcn].stripped_output_names
  end

  def decode(*syms)
    syms.collect do |sym|
      self.send(sym)
    end
  end
end

def ts(symbol, seconds, options={ })
  $ts = Timeseries.new(symbol, seconds, options)
  nil
end

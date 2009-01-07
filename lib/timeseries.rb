class Timeseries

  DEFAULT_OPTIONS = { DailyClose => { :attrs => [:date, :volume, :high, :low, :open, :close, :r, :logr],
                                      :sample_period => 60*60*24,
                                      :start_time => Time.parse('2000-1-1'),
                                      :end_time => Time.now },
                     LiveQuote => { :attrs => [:last_trade, :volume, :change_points, :r, :logr],
                                    :sample_period => 60,
                                    :start_time => Time.parse('2000-1-1'),
                                    :end_time => Time.now }
  }
  attr_accessor :symbol, :source_model, :value_hash, :time_interval
  attr_accessor :start_time, :end_time, :num_points, :sample_period
  attr_accessor :attrs, :derived_values
  attr_accessor :timevec, :time_map, :local_focus

  def initialize(symbol, source_model, options)
    raise ArgumentError, "source_model must be one of #{DEFAULT_OPTIONS.keys.join(' or ')}" unless [ DailyClose, LiveQuote ].include? source_model
    self.symbol = symbol
    self.value_hash = {}
    self.time_map = {}
    self.local_focus = nil
    self.derived_values = []
    options.reverse_merge!(DEFAULT_OPTIONS[source_model])
    apply_options()
    repopulate({}) if options[:populate]
    add_methods_for_attributes(value_hash.keys)
  end

  def repopulate(options)
    apply_options unless options.empty?
    if num_points
      self.value_hash = source_model.simple_vectors(symbol, attrs, start_time, num_points)
    elsif time_interval
      self.value_hash = source_model.general_vectors_by_interval(symbol, attrs, start_time, time_interval)
    else
      self.value_hash = source_model.general_vectors(symbol, attrs, start_time, end_time)
    end
    compute_timestamps
  end

  private

  def apply_options
    options.keys.each do |key|
      self.send(key, options[key]) if respond_to? key
    end
  end

  def compute_timestamps
    self.timevec = value_hash[source_model.timecol].collect(&:to_time)
    self.timevec.each_with_index { |time, idx| self.time_map[time] = idx }
    self.value_hash.delete(source_model.timecol)
    nil
  end

  def beg_index(ta_fun, *args)
    loopback_fun = (ta_fun.to_s+'_loopback').to_sym
    idx = Talib.send(loopback_fun, args)
  end

  def memoize_result(fcn, time_range, options, outidx, vec)
    self.derived_values << ParamBlock.new(fcn, time_range, options, outidx, vec)
  end

  def ad(time_range=nil, options={ })
    beg_idx, end_idx = calc_indexes(time_range, options)
    status, outidx, vec = Talib.ta_ad(beg_idx, end_idx, high, low, close, volume)
    memoize_result(:ad, time_range, options, outidx, vec, :line)
  end

  def add_methods_for_attributes(attrs)
    attrs.each do |attr|
      instance_eval("def #{attr}(); self.value_hash[#{attr}.to_sym]; end")
    end
  end

  def method_missing(meth, *args)
    source_model.content_columns.map(&:name).include? meth
  end
end

class ParamBlock
  attr_accessor :function
  attr_accessor :time_rage
  attr_accessor :options
  attr_accessor :outidx
  attr_accessor :result
  attr_accessor :graph_type

  def initialize(fcn, tr, opts, outidx, result, gtype)
    self.function = fcn
    self.time_range = tr
    self.options = opts
    self.outidx = outidx
    self.result = result
    self.graph_type = gtype
  end
end

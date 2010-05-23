# Copyright © Kevin P. Nolan 2009 All Rights Reserved.
class AnalResults

  include ResultAnalysis
  include Enumerable

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
    self.names = TALIB_META_INFO_DICTIONARY[fcn].stripped_output_names.map(&:to_sym)
    self.timeseries = ts
    self.result_hash = {}

    raise ArgumentError, "Output Index is not same as Index Rage, increase pre-buffer" if outidx != index_range.begin && outidx != 0

    self.names.each_with_index { |name, idx| self.result_hash[name.to_sym] = vectors[idx] }
  end

  def extended_range?
    false
  end

  def result_for(index, vector_idx=0)
    raise ArgumentError, "Seoncd arg can only be the index of the output vector" unless vector_idx.class == Fixnum
    vectors[vector_idx][index-outidx]
  end

  def vector_for(sym)
    case
    when result_hash.has_key?(sym)                then result_hash[sym]
    when timeseries.value_hash.has_key?(sym)      then timeseries.value_hash[sym][index_range].to_gv
    when timeseries.methods.include?(sym.to_s)    then timeseries.send(sym)[index_range].to_gv
    else
      raise ArgumentError, "#{function}.#{sym} is not available"
    end
  end

  # FIXME this only fetches the first result of a possilby multi-result indicator
  # FIXME I'm not sure how to get around this as you cannot pass parameters to each (I don't think)
  def each
    i = -1
    vectors.first.each { |e| i+=1; yield [e, timeseries.index2time(i+outidx)] }
  end

  def each_from_result(sym)
    raise ArgumentError, "#{sym} is not a valid result for #{function}" unless names.include? sym.to_sym
    i = -1
    result_hash[sym.to_sym].each { |e| i+=1; yield [e, timeseries.index2time(i+outidx)] }
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

  def generate_csv()
    basename = names.join('_')
    path = File.join(RAILS_ROOT, 'tmp', basename+'.csv')
    timevec = timeseries.timevec[index_range].map { |d| d.to_formatted_s(:ymd) }
    count = timevec.length
    FasterCSV.open(path, "w") do |csv|
      csv << ['date'].concat(result_hash.keys)
      count.times do |i|
        csv << [timevec[i]].concat(result_hash.keys.map { |k| result_hash[k][i] })
      end
    end
  end
end

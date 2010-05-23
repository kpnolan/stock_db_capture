# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'rbgsl'

module CsvDumper

  OCHLV = [:bartime, :opening, :high, :low, :close, :volume]

  include GSL

  def append_technical_indicators(indicators)
    for ti_block in indicators
      index_range, vecs, names = ti_block.decode(:index_range, :vectors, :names)
      if index_range != @common_range
        raise ArgumentError, "index_range is different for #{ti_block.function} than previous indicators (#{@common_range} != #{index_range})"
      end
      names = names.dup
      vecs.each do |vec|
        @names_array << names.shift
        @values_array << vec.to_a
      end
    end
  end

  def dump_to_file(file_name)
    raise ArgumentError, "TimeSeries must include at least one technical indicator" if derived_values.empty?
    @common_range = derived_values.first.index_range
    @values_array = []
    @names_array = []
    OCHLV.each do |attr|
      @names_array << attr
      @values_array << value_hash[attr][@common_range].to_a
    end
    append_technical_indicators(self.derived_values)
    CSV.open(file_name, "w") do |csv|
      csv << @names_array
      for row in @values_array.transpose
        csv << row
      end
    end
  end
end

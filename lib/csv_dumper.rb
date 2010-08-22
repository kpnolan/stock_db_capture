#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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

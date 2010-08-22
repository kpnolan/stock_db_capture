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

module ExcelOutput

  BAR_LABELS = %w{ date  open high low close }

  def dump_finance_vectors()

    date = set_xvalues(plot, self.timevec[index_range])
    open = open_before_cast[index_range]
    close = close_before_cast[index_range]
    high = high_before_cast[index_range]
    low = low_before_cast[index_range]

    vecs = []
    names = []
    index_range = nil
    len = 0
    derived_values.each do |param|
      if param.graph_type == :overlap
        pindex_range, pvecs, pnames = param.decode(:index_range, :vectors, :names)
        vecs << pvecs
        names << pnames
        len = pindex_range.end - pindex_range.begin + 1
        index_range = pindex_range
      end
    end
    vecs.flatten!
    names.flatten!

    CSV.open('./tmp/xl.csv') do |csv|
      csv << BAR_LABELS + names
      [date].zip(open, high, low, close, *vecs) do |vec|
        csv << vec
      end
    end
  end
end

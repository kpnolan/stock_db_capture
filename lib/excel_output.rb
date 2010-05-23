# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

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

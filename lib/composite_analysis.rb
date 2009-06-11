module CompositeAnalysis
  def intersect(idx_ary1, idx_ary2, overlap_period)
    tuples = []
    ary1_len = idx_ary1.length
    ary2_len = idx_ary2.length
    offset1 = 0
    offset2 = 0
    while offset1 < ary1_len and offset2 < ary2_len
      idx1 = idx_ary1[offset1]
      idx2 = idx_ary2[offset2]
      t1 = index2time(idx1)
      t2 = index2time(idx2)
      delta = (t1 - t2).to_i
      if delta <= overlap_period and delta >= 0
        tuples << [idx1, idx2, delta]
        $deltas << delta
      end
      case
      when idx1 < idx2    : offset1 += 1
      when idx1 > idx2    : offset2 += 1
      else
        offset1 += 1
        offset2 += 1
      end
    end
    tuples
  end
end

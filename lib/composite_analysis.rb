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
      when idx1 < idx2 then offset1 += 1
      when idx1 > idx2 then offset2 += 1
      else
        offset1 += 1
        offset2 += 1
      end
    end
    tuples
  end
end

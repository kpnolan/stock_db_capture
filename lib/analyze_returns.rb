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

module AnalyzeReturns

  class << self

    def position_histogram(value, sigma=2.0)

      avg = do_query("avg(#{value})").first.to_f
      stddev = do_query("stddev(#{value})").first.to_f
      min = avg - sigma*stddev
      max = avg + sigma*stddev
      hist = GSL::Histogram.alloc(100, min, max)

      nreturns = do_query('roi').map! { |str| str.to_f }
      nreturns.each { |r| hist.accumulate(r) }

      hist.graph('-C')
      hist.graph('-T gif -C')
    end

    def do_query(value)
      sql = "select #{value} from positions where nreturn is not null"
      Position.connection.select_values(sql)
    end

    def position_pdf(value, sigma=2.0)
      avg = do_query("avg(#{value})").first.to_f
      stddev = do_query("stddev(#{value})").first.to_f
      min = avg - sigma*stddev
      max = avg + sigma*stddev
      hist = GSL::Histogram.alloc(500, min, max)

      nreturns = Position.connection.select_values("select nreturn from positions").map! { |str| str.to_f }
      nreturns.each { |r| hist.accumulate(r) }
      pdf = GSL::Histogram::Pdf.alloc(hist)
    end
  end
end



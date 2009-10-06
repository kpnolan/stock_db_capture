# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

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



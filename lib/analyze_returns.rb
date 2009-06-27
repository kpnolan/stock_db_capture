# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'rbgsl'

module AnalyzeReturns

  class << self

    def nreturn_histogram(strategy, sigma)

      avg = do_query(strategy, 'avg(nreturn)').first.to_f
      stddev = do_query(strategy, 'stddev(nreturn)').first.to_f
      min = avg - sigma*stddev
      max = avg + sigma*stddev
      #max = Position.maximum(:nreturn, :conditions => 'nreturn is not null')
      #min = Position.minimum(:nreturn, :conditions => 'nreturn is not null')
      hist = GSL::Histogram.alloc(100, min, max)

      nreturns = do_query(strategy, 'nreturn').map! { |str| str.to_f }
      nreturns.each { |r| hist.accumulate(r) }

      hist.graph('-C')
      hist.graph('-T gif -C')
    end

    def do_query(strategy, value)
      sql = "select #{value} from positions left outer join strategies on strategies.name = '#{strategy}' "+
            "where strategy_id = strategies.id and nreturn is not null"
      Position.connection.select_values(sql)
    end

    def nreturn_pdf()
      #avg = Position.average(:nreturn, :conditions => 'nreturn is not null')
      #stddev = Position.connection.select_value('select stddev(nreturn) from positions where nreturn is not null').to_f
      #min = avg - 2*stddev
      #max = avg + 2*stddev
      max = Position.maximum(:nreturn, :conditions => 'nreturn is not null')
      min = Position.minimum(:nreturn, :conditions => 'nreturn is not null')
      hist = GSL::Histogram.alloc(500, min, max)

      nreturns = Position.connection.select_values("select nreturn from positions where exit_price is not null").map! { |str| str.to_f }
      nreturns.each { |r| hist.accumulate(r) }
      pdf = GSL::Histogram::Pdf.alloc(hist)

      pdf.graph('-C')
            hist.graph('-C')
      hist.graph('-T gif -C')
    end
  end
end



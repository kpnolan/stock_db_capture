require 'rubygems'
require 'rbgsl'
require 'ruby-debug'


module AnalyzeReturns

  class << self

    def nreturn_histogram(val, sigma)

      avg = Position.average(val, :conditions => 'nreturn is not null')
      stddev = Position.connection.select_value("select stddev(#{val}) from positions where nreturn is not null").to_f
      min = avg - sigma*stddev
      max = avg + sigma*stddev
      #max = Position.maximum(:nreturn, :conditions => 'nreturn is not null')
      #min = Position.minimum(:nreturn, :conditions => 'nreturn is not null')
      hist = GSL::Histogram.alloc(400, min, max)

      nreturns = Position.connection.select_values("select #{val} from positions where nreturn is not null").map! { |str| str.to_f }
      nreturns.each { |r| hist.accumulate(r) }

#      debugger

      hist.graph('-C')
      hist.graph('-T gif -C')
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



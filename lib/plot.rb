require 'rubygems'
require 'gnuplot'
require 'rbgsl'
require 'gsl/gnuplot'

module Plot
  include GSL

  def plotdc(symbol, attrs = [])

    vhash = DailyClose.get_vectors(symbol, attrs)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

#        plot.xrange "[0:#{len-1}]"
#        plot.yrange "[0:#{ymax}]"
        plot.auto "x"
        plot.auto "y"
        plot.title  "#{symbol}: #{vhash.keys.join(',')}"
        plot.xlabel "Date"
        plot.ylabel "#{vhash.keys.join(', ')}"
        plot.pointsize 3
        plot.grid

        plot.data = []
        vhash.keys.each do |attr|
          if attr == :volume
            new_vec = scale(vhash[attr])
            plot.data << Gnuplot::DataSet.new( new_vec ) {  |ds|  ds.with = "boxes" }
          else
            plot.data << Gnuplot::DataSet.new( vhash[attr] ) {  |ds|  ds.with = "lines" }
          end
        end
      end
    end
    nil
  end

  def plotrt(symbol, attrs = [])

    vhash = RealTimeQuote.get_vectors(symbol, attrs)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

#        plot.xrange "[0:#{len-1}]"
#        plot.yrange "[0:#{ymax}]"
        plot.auto "x"
        plot.auto "y"
        plot.title  "#{symbol}: #{vhash.keys.join(',')}"
        plot.xlabel "Date"
        plot.ylabel "#{vhash.keys.join(', ')}"
        plot.pointsize 3
        plot.grid

        plot.data = []

        vhash.keys.each do |attr|
          if attr == :volume
            new_vec = scale(vhash[attr])
            plot.data << Gnuplot::DataSet.new( new_vec ) {  |ds|  ds.with = "boxes" }
          else
            plot.data << Gnuplot::DataSet.new( vhash[attr] ) {  |ds|  ds.with = "lines" }
          end
        end
      end
    end
    nil
  end

  def scale(vec)
    gvec = vec.to_gv
    max = gvec.max
    lmax = Math.log10(max)-1
    gvec.scale!(1/10**lmax)
    gvec.to_a
  end

  def histogram(symbol, attr)
    vhash = DailyClose.get_vectors(symbol, attr)
    gvec = vhash[attr].to_gv
    h = gvec.histogram(50)
    xvec = GSL::Vector.linspace(gvec.min, gvec.max, 50).to_a

    bins = h.bin.to_a

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.style "histogram clustered gap 3"
        plot.style "fill solid 1.0 border -1"
        plot.xrange "[#{gvec.min}:#{gvec.max}]"

        plot.data = [ Gnuplot::DataSet.new( [xvec, bins] ) { |ds| ds.with = "boxes" } ]
      end
    end
    nil
  end

  def wma(periodLength, values)
    sum = 0;
    weightedSum = 0;
    for n in 0..periodLength
      weightedSum = weightedSum + ((periodLength - n) * values[n]);
      sum = sum + n;
    end
    return weightedSum / sum;
  end

end

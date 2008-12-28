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

  def test(symbol, attrs = [])

    attr = :close
    vhash = DailyClose.get_vectors(symbol, [:date, :close])

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "#{symbol}: #{vhash.keys.join(',')}"
        plot.xlabel "Date"
        plot.ylabel "#{vhash.keys.join(', ')}"
        plot.pointsize 3
        plot.grid
        plot.xdata "time"
        plot.timefmt '"%Y-%m-%d"'

        date = vhash[:date].collect { |date| date.to_s(:db) }

        plot.data = []
        if attr == :volume
          new_vec = scale(vhash[attr])
          plot.data << Gnuplot::DataSet.new( new_vec ) {  |ds|  ds.with = "boxes" }
        else
          plot.data << Gnuplot::DataSet.new( [date, vhash[:close]] ) {  |ds| ds.using = "1:2"; ds.with = "lines" }
        end
      end
    end
    nil
  end

  def candle_dc(symbol, bdate, period)

    attrs = [:date, :open, :low, :high, :close, :volume ]

    vhash = DailyClose.get_vectors(symbol, attrs, bdate, period)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "Candlestics for #{symbol}"
        plot.xlabel "Date"
        plot.ylabel 'OCHL'
        plot.pointsize 3
        plot.grid
        plot.xdata "time"
        plot.timefmt '"%Y-%m-%d"'
        plot.xtics 'scale default'

        open = vhash[:open]
        close = vhash[:close]
        high = vhash[:high]
        low = vhash[:low]
        date = vhash[:date]

        plot.data = []
        plot.data << Gnuplot::DataSet.new( [date, open, low, high, close] ) {  |ds|  ds.using="1:2:3:4:5"; ds.with = "candlesticks" }
        volume = scale(vhash[:volume])
        plot.data << Gnuplot::DataSet.new( volume ) {  |ds|  ds.with = "boxes" }
      end
    end
    nil
  end

  def candle_live(symbol, bdate, period)

    attrs = [:start, :low, :high, :open, :close, :volume ]

    vhash = Aggregate.get_vectors(symbol, attrs, bdate, period)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "Intra Day Candlestics for #{symbol}"
        plot.xlabel "Date/Time"
        plot.ylabel 'OCHL'
        plot.pointsize 3
        plot.grid
        plot.xdata "time"
        plot.xtic 60*60
        plot.timefmt '"%Y-%m-%d^%H:%M:%S"'
        plot.xformat "%d/%m\n%H:%M"

        timevec = vhash[:start].collect { |td| td.to_s(:db).gsub(/[ ]/,'^') }
        vhash.delete :start

        open = vhash[:open]
        close = vhash[:close]
        high = vhash[:high]
        low = vhash[:low]

        plot.data = []
        plot.data << Gnuplot::DataSet.new( [timevec, open, low, high, close] ) {  |ds|  ds.using="1:2:3:4:5"; ds.with = "candlesticks rgb black" }
        volume = scale(vhash[:volume])
        plot.data << Gnuplot::DataSet.new( volume ) {  |ds|  ds.with = "boxes" }
      end
    end
    nil
  end

  def plotrt1(symbol, attrs = [])

    vhash = RealTimeQuote.get_vectors(symbol, attrs + [:last_trade_time])
    min_time = vhash[:last_trade_time].first
    max_time = min_time + 8.hour
    vhash = RealTimeQuote.get_vectors(symbol, attrs + [:last_trade_time], min_time, max_time)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "#{symbol}: #{vhash.keys.join(',')}"
        plot.xlabel "Date"
        plot.ylabel "#{vhash.keys.join(', ')}"
        plot.pointsize 3
        plot.grid
        plot.xdata "time"
        plot.xtic 60*60
        plot.timefmt '"%Y-%m-%d-%H:%M:%S"'


        timevec = vhash[:last_trade_time].collect { |td| td.to_s(:db).gsub(/[ ]/,'-') }
        vhash.delete :last_trade_time

        plot.data = []

        vhash.keys.each do |attr|
          if attr == :volume
            new_vec = scale(vhash[attr])
            plot.data << Gnuplot::DataSet.new( [timevec, new_vec] ) {  |ds|  ds.using = "1:2"; ds.with = "boxes" }
          else
            plot.data << Gnuplot::DataSet.new( [timevec, vhash[attr]] ) {  |ds| ds.using="1:2";  ds.with = "lines" }
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

  def plotrt1(symbol, attrs = [])

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
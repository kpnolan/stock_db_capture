require 'rubygems'
require 'gnuplot'
require 'rbgsl'
require 'gsl/gnuplot'

module Plot

  PLOT_TYPES = [ :line, :bar, :candlestick ]

  include GSL

  def plot_lines(symbol, attrs = [], start=nil, num_points=nil)

    vhash = simple_vectors(symbol, attrs, start, num_points)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "#{symbol}: #{titleize(vhash.keys)}"
        plot.xlabel time_class.to_s
        plot.ylabel "#{titleize(vhash.keys)}"
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

  def set_xvalues(plot, time_vector)
    time_class = time_vector.first.send(time_convert).class
    plot.xdata "time"
    if time_class == Date
      plot.timefmt '"%Y-%m-%d"'
      plot.format 'x "%m-%d"'
      time_vector
    elsif time_class == Time || time_class == DateTime
      plot.timefmt '"%Y-%m-%d@%H:%M"'
      plot.format 'x "%m-%d\n%H:%M"'
      time_strings = time_vector.map { |time| time.to_s().gsub(/[ ]/, '@') }
    end
  end

  def plot_ts(symbol, attrs, start, period)

    start = time_class.parse(start) if start.class == String
    start = start.send(time_convert)

    vhash = general_vectors(symbol, attrs, start, period)
    timevec = simple_vector(symbol, time_col, start, period)
    len = timevec.length

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "#{symbol}: #{titleize(vhash.keys)}"
        plot.xlabel "Date from #{start.to_s(:db)} to #{start+period} (#{len} points)"
        plot.ylabel "#{titleize(vhash.keys)}"
        plot.pointsize 3
        plot.grid

        timevec = set_xvalues(plot, timevec)

        plot.data = []
        vhash.keys.each do |attr|
          if attr == :volume
            plot.data << Gnuplot::DataSet.new( [timevec, scale(vhash[attr])] ) {  |ds|  ds.using = "1:2"; ds.with = "boxes" }
          else
            plot.data << Gnuplot::DataSet.new( [timevec, vhash[attr]] ) {  |ds|  ds.using = "1:2"; ds.with = "lines" }
          end
        end
      end
    end
    nil
  end

  def composite(symbol, start, period, with, show_volume=false)

    start = time_class.parse(start) if start.class == String
    start = start.send(time_convert)

    attrs = [ time_col.to_sym, :low, :high, :open, :close, :volume ]

    vhash = general_vectors(symbol, attrs, start, period)
    len = vhash[:close].length

    vhash = general_vectors(symbol, attrs, start, period)

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.title  "Candlestics for #{symbol}"
        plot.xlabel "Date from #{start.to_s(:db)} to #{start+period} (#{len} points)"
        plot.ylabel 'OCHL'
        plot.pointsize 3
        plot.grid
        plot.bars "3.0"

        date = set_xvalues(plot, vhash[time_col.to_sym])

        open = vhash[:open]
        close = vhash[:close]
        high = vhash[:high]
        low = vhash[:low]

        plot.data = []
        plot.data << Gnuplot::DataSet.new( [date, open, low, high, close] ) {  |ds|  ds.using="1:2:3:4:5"; ds.with = "#{with} lw 2" }
        volume = scale(vhash[:volume])
        plot.data << Gnuplot::DataSet.new( [date, volume] ) {  |ds|  ds.using = "1:2"; ds.with = "boxes" } if show_volume
      end
    end
    nil
  end

  def candlestick(symbol, start, period, show_volume=false)
    composite(symbol, start, period, 'candlestick', show_volume=false)
  end

  def bar(symbol, start, period, show_volume=false)
    composite(symbol, start, period, 'financebar', show_volume=false)
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

  def titleize(syms)
    syms.map { |sym| sym.to_s.titleize }.join(', ')
  end
end

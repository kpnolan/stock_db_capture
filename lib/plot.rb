require 'rubygems'
require 'gnuplot'
require 'rbgsl'
require 'gsl/gnuplot'

module Plot
  include GSL

  def vec(symbol, attrs=nil, bdate=nil, edate=nil)
    vhash = DailyClose.get_vectors(symbol, attrs, bdate, edate)
    vclose = vhash[:close]
    gvclose = vclose.to_gv
    len = gvclose.len
    ymax = gvclose.max

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.xrange "[0:#{len-1}]"
        plot.yrange "[0:#{ymax}]"
        plot.title  "#{symbol}: #{attrs.join(',')}"
        plot.xlabel "Date"
        plot.ylabel "Attr"
        plot.pointsize 3
        plot.grid

        x = GSL::Vector[0..10]
#        x = (0..(len-1)).to_a
        y = gvclose

        plot.data = [
          Gnuplot::DataSet.new( [x, y] ) do |ds|
                       ds.with = "lines"
                     end
                    ]

      end
    end
  end

  def vec1(symbol, attrs=nil, bdate=nil, edate=nil)
    vhash = DailyClose.get_vectors(symbol, attrs, bdate, edate)
    gvclose = vhash[:close].to_gv
    len = gvclose.len
    ymax = gvclose.max

    plot = Gnuplot::Plot.new( );
    debugger
    a = 1
    b = 2
  end

  def plot1
    plot =  Gnuplot::Plot.new(  ) do |plot|

      plot.xrange "[0:10]"
      plot.yrange "[-1.5:1.5]"
      plot.title  "Sin Wave Example"
      plot.xlabel "x"
      plot.ylabel "sin(x)"
      plot.pointsize 3
      plot.grid


      x = (0..10).to_a
      y = x.collect { |i| Math.sin(i) }

      plot.data = [
                   Gnuplot::DataSet.new( "sin(x)" ) do |ds|
                     ds.with = "lines"
                     ds.title = "String function"
                     ds.linewidth = 40
      end,

       Gnuplot::DataSet.new( [x, y] ) { |ds|
         ds.with = "linespoints"
         ds.title = "Array data"
       }
                ]

    end
    debugger
    a =1
    b =2
  end
end


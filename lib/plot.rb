# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'gnuplot'
require 'rbgsl'
require 'gsl/gnuplot'

module Plot

  PLOT_TYPES = [ :line, :financebar, :candlestick ]

  include GSL
  include PlotAuxInfo

  def plot_lines(index_range, timevec, *vecs_or_params)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.unset 'title'
        plot.unset 'xlabel'
        plot.unset 'ylabel'
        plot.pointsize 3
        plot.grid
        timevec = set_xvalues(plot, self.timevec[index_range])

        plot.data = []
        vecs_or_params.each do |vec|
          unless vec.extended_range?
            plot.data << Gnuplot::DataSet.new( [timevec, vec.to_a] ) {  |ds|  ds.using = "1:2"; ds.with = "lines" }
          else
            plot.data << Gnuplot::DataSet.new( [timevec, vec.to_a[index_range]] ) {  |ds|  ds.using = "1:2"; ds.notitle; ds.with = "lines" }
          end
        end
      end
      nil
    end
  end

  def plot_histogram(hist)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.auto "x"
        plot.auto "y"
        plot.unset 'title'
        plot.unset 'xlabel'
        plot.unset 'ylabel'
        plot.style "histogram"
        plot.grid
        plot.boxwidth "0.9 relative"
        plot.style "data histograms"
        plot.style "fill solid 1.0 border -1"

        vec = Array.new(hist.bins/20)
        0.upto(vec.length-1) do |i|
          vec[i] = hist[i]
        end
        plot.data = []
        plot.data <<  Gnuplot::DataSet.new( vec ) {   }
      end
      nil
    end
  end

  def plot_ts(gp, vecs, index_range, options)

    Gnuplot::Plot.new( gp ) do |plot|
      plot.auto "x"
      plot.auto "y"
      plot.unset "xlabel"
      plot.unset 'grid'
      plot.unset 'ylabel'
      plot.unset 'title'
      plot.set 'bmargin'
      plot.xtics 'scale default'
      plot.tmargin 0
#      plot.xlabel "Date from #{index2time(index_range.begin).to_s(:db)} to #{index2time(index_range.end).to_s(:db)} (#{len} points)"
      plot.origin options[:origin] if options[:origin]
      plot.size options[:size] if options[:size]

      timevec = set_xvalues(plot, self.timevec[index_range])
      withs = options[:with]

      plot.data = []
      vecs.each do |vec|
        with = withs.shift()
        plot.data << Gnuplot::DataSet.new( [timevec, vec.to_a[index_range]] ) {  |ds|  ds.using = "1:2"; ds.notitle; ds.with = with }
      end
    end
  end

  def plot_params(gp, param, options)
    Gnuplot::Plot.new( gp ) do |plot|
      plot.style 'line 1 lt 1 lw 1'
      plot.style 'line 2 lt 2 lw 1'
      plot.style 'line 3 lt 3 lw 1'
      plot.style 'line 4 lt 6 lw 1'
      plot.pointsize
      plot.style 'increment user'
      plot.auto "x"
      plot.auto "y"
      plot.unset "xlabel"
      plot.unset 'ylabel'
      plot.unset 'title'
      plot.set 'bmargin'
      plot.xtics 'scale default'
      plot.tmargin 0
#      plot.xlabel "Date from #{index2time(index_range.begin).to_s(:db)} to #{index2time(index_range.end).to_s(:db)} (#{len} points)"
      plot.origin options[:origin] if options[:origin]
      plot.size options[:size] if options[:size]
      plot.script plot_commands_for param.function
      index_range, vecs, names = param.decode(:index_range, :vectors, :names)
      names = names.dup

      timevec = set_xvalues(plot, self.timevec[index_range])
      close = close_before_cast[index_range]

      vec = vecs.first
#       puts "close len: #{close.length}"
#       puts "result leng: #{vec.len}"
#       i = 0
#       for c in close
#         puts "#{timevec[i]} -- close: #{c} result: #{vec[i]}"
#         i += 1
#       end

      plot.data = []
      vecs.each do |vec|
        plot.data << Gnuplot::DataSet.new( [timevec, vec.to_a] ) {  |ds|  ds.using = "1:2"; ds.title = names.shift; ds.with = 'lines' }
      end
    end
  end

  def normalize(vec)
    vec.each_with_index { |e, i| vec[i] = i }
  end

  def set_xvalues(plot, timevec)
    return normalize(timevec) if timevec.first.is_a? Fixnum
    time_class = timevec.first.send(model.time_convert).class
    if time_class == Date
      plot.xdata "time"
      plot.timefmt '"%Y-%m-%d"'
      plot.format 'x "%m-%d\n%Y"'
      timevec.map { |t| t.to_date }
#      timevec.map { |t| '"'+t.strftime('%Y-%m-%d')+'"' }
    elsif time_class == Time || time_class == DateTime
      plot.xdata "time"
      plot.timefmt '"%Y-%m-%d@%H:%M"'
      plot.format 'x "%m-%d\n%H:%M"'
      timevec.map { |t| '"'+time.strftime('%Y-%m-%d@%H:%M')+'"' }
    end
  end

  def set_yrange(plot, low_vec, high_vec)
    low_f = low_vec.map { |e| e.to_f }
    high_f = high_vec.map { |e| e.to_f }

    plot.yrange "[ #{low_f.min*0.995} : #{high_f.max*1.005} ]"
  end

  def aggregate(symbol, param, options)

    index_range, vecs, names = param.decode(:index_range, :vectors, :names)
    len = index_range.end - index_range.begin + 1

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.mouse 'mouseformat 3'
        plot.auto "x"
        plot.auto "y"
        plot.title  "#{param.function.to_s.upcase} for #{symbol}: #{Ticker.listing_name(symbol)}"
        plot.xlabel "Date from #{index2time(index_range.begin).to_s(:db)} to #{index2time(index_range.end).to_s(:db)} (#{len} points)"
        plot.ylabel 'OCHL'
        plot.pointsize 3
        plot.grid
        plot.size "1,1"
        plot.origin "0,0"
        plot.boxwidth 0.2 if options[:with] == 'candlesticks'

        names = names.dup

        date = set_xvalues(plot, self.timevec[index_range])
        open = open_before_cast[index_range]
        close = close_before_cast[index_range]
        high = high_before_cast[index_range]
        low = low_before_cast[index_range]

        set_yrange(plot, low, high)

        plot.data = []
        plot.data << Gnuplot::DataSet.new( [date, open, low, high, close] ) {  |ds| ds.using="1:2:3:4:5"; ds.title = 'OHLC'; ds.with = options[:with] }
        vecs.each do |vec|
          plot.data << Gnuplot::DataSet.new( [date, vec.to_a] ) {  |ds|  ds.using = "1:2"; ds.title = names.shift; ds.with = "lines" }
        end
      end
    end
    nil
  end

  def aggregate_all(symbol, options)

    vecs = []
    names = []
    index_range = nil
    len = 0
    derived_values.each do |param|
      if param.graph_type == :overlap
        pindex_range, pvecs, pnames = param.decode(:index_range, :vectors, :names)
        vecs << pvecs
        names << pnames
        len = pindex_range.end - pindex_range.begin + 1
        index_range = pindex_range
      end
    end
    vecs.flatten!
    names.flatten!

    fcn_names = derived_values.collect { |pb| pb.function.to_s }.join(', ')

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.mouse 'mouseformat 3'
        plot.auto "x"
        plot.auto "y"
        plot.title  "#{fcn_names} for #{symbol}: #{Ticker.listing_name(symbol)}"
        plot.xlabel "Date from #{index2time(index_range.begin).to_s(:db)} to #{index2time(index_range.end).to_s(:db)} (#{len} points)"
        plot.ylabel 'OCHL'
        plot.pointsize 3
        plot.grid
        plot.size "1,1"
        plot.origin "0,0"
        plot.boxwidth 0.2 if options[:with] == 'candlesticks'

        names = names.dup

        date = set_xvalues(plot, self.timevec[index_range])
        open = open_before_cast[index_range]
        close = close_before_cast[index_range]
        high = high_before_cast[index_range]
        low = low_before_cast[index_range]

        set_yrange(plot, low, high)

        plot.data = []
        plot.data << Gnuplot::DataSet.new( [date, open, low, high, close] ) {  |ds| ds.using="1:2:3:4:5"; ds.title = 'OHLC'; ds.with = options[:with] }
        vecs.each do |vec|
          plot.data << Gnuplot::DataSet.new( [date, vec.to_a] ) {  |ds|  ds.using = "1:2"; ds.title = names.shift; ds.with = "lines" }
        end
      end
    end
    nil
  end


  def aggregate_base(plot, index_range, options)
    len = index_range.end - index_range.begin + 1

    plot.mouse 'mouseformat 3'
    plot.auto "x"
    plot.auto "y"
    plot.title  "#{options[:title].to_s.capitalize} for #{symbol}: #{Ticker.listing_name(symbol)}"
    plot.ylabel 'OCHL'
    plot.pointsize 3
    plot.grid
    plot.bars 1.0
    plot.unset 'xtics'
    #       plot.bars "lw .5"
    #       plot.line "lw .5"
    plot.boxwidth 0.2 if options[:with] == 'candlesticks'
    plot.multiplot if options[:multiplot]
    plot.origin options[:origin] if options[:origin]
    plot.size options[:size] if options[:size]

    date = set_xvalues(plot, self.timevec[index_range])
    open = open_before_cast[index_range]
    close = close_before_cast[index_range]
    high = high_before_cast[index_range]
    low = low_before_cast[index_range]
    plot.data = []
    plot.data << Gnuplot::DataSet.new( [date, open, low, high, close] ) {  |ds| ds.using="1:2:3:4:5"; ds.title = 'OHLC'; ds.with = options[:with] }
  end

  def with_volume(index_range)
    multiplot(index_range, :multiplot => true, :origin => '0, .3', :size => '1, 0.7', :with => 'financebars') do |gp|
      plot_ts(gp, [volume], index_range, :origin => '0, 0', :size => '1, 0.3', :with => ['boxes'])
    end
  end

  def with_function(function)
    raise TimeseriesException.new("Cannot find memoized function: #{function}") if (pb = find_memo(function)).nil?
    multiplot(pb.index_range, :script => true, :prefix => function.to_s, :title => function, :exec => true, :origin => '0, .3', :size => '1, 0.7', :with => pb.graph_type.nil? ? 'financebars' : pb.graph_type) do |gp|
      plot_params(gp, pb, :origin => '0, 0', :size => '1, 0.3')
    end
  end

  def multiplot(index_range, options, &block)
    Gnuplot.open(true, options.merge(:multiplot => true)) do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        aggregate_base(plot, index_range, options)
      end
      yield gp unless block.nil?
    end
  end

  def candlestick(symbol, index_range, options={})
    aggregate(symbol, index_range, options.merge(:with => 'candlesticks'))
  end

  def bar(symbol, index_range, options={})
    aggregate(symbol, index_range, options.merge(:with => 'financebar'))
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

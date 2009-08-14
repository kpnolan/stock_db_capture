class WatchListsController < ApplicationController
  make_resourceful do
    actions :all

    before :index do
      puts "calling before..."
    end

    after :index do
      puts "calling after..."
      session[:prev_prices] = session[:prices]
    end
  end

  def current_objects
    wl = WatchList.find(:all, :include => :ticker, :order => 'crossed_at, tickers.symbol')
    session[:prices] = wl.inject({}) { |h, obj| h[obj.ticker_id] = obj.price; h}
    session[:prev_prices] ||= session[:prices]
    wl
  end

  def plot
   puts "echo plot.rt.snap('#{current_object.ticker.symbol}') | R --no-save"
    `echo "plot.rt.snap('#{current_object.ticker.symbol}')" | R --no-save`
    send_file File.join(RAILS_ROOT, 'Rplots.pdf')
  end

  def open
  end

  def close
  end

end

class WatchListsController < ApplicationController
  make_resourceful do
    actions :all
  end

  def current_objects
    WatchList.find(:all, :include => :ticker, :order => 'tickers.symbol')
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

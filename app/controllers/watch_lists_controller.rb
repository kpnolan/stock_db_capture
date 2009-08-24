class WatchListsController < ApplicationController
  make_resourceful do
    actions :all

    after :index, :exits do
      session[:prev_prices] = session[:prices]
    end

    before :delete do
      positions = TdaPosition.find(:all, :conditions => { :watch_list_id => current_object.id } )
      positions.each do |positions|
        position.update_attribute(:watch_list_id, nil)
      end
    end
  end

  def current_objects
    wl = WatchList.find(:all, :include => :ticker, :order => 'open_crossed_at, tickers.symbol')
    session[:prices] = wl.inject({}) { |h, obj| h[obj.ticker_id] = obj.price; h}
    session[:prev_prices] = session[:prices] if session[:prev_prices].nil? or session[:prev_prices].keys != session[:prices].keys
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

  def retire
  end

  def exits
  end
end

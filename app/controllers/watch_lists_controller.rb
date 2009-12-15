module Resourceful
  module Default
    module Actions
      # GET /foos
      def exits
        load_objects
        before :exits
        response_for :exits
        after :exits
      end
      def index
        load_objects
        before :index
        response_for :index
        after :index
      end
    end
  end
end

class WatchListsController < ApplicationController

  layout 'watch_list'

  attr_reader :current_objects

  make_resourceful do
    actions :all

    before :exits do
      self.sort_order ||=  'open_crossed_at desc, price'
      @current_objects = wl = WatchList.all(:conditions => 'opened_on is not null', :include => :ticker, :order => sort_order)
      session[:prices] = wl.inject({}) { |h, obj| h[obj.ticker_id] = obj.price; h}
      session[:prev_prices] = session[:prices] if session[:prev_prices].nil? or session[:prev_prices].keys != session[:prices].keys
    end

    before :index do
      self.sort_order ||=  'open_crossed_at desc, price'
      @current_objects = wl = WatchList.find(:all, :include => :ticker, :conditions => 'opened_on is null', :order => sort_order)
      session[:prices] = wl.inject({}) { |h, obj| h[obj.ticker_id] = obj.price; h}
      session[:prev_prices] = session[:prices] if session[:prev_prices].nil? or session[:prev_prices].keys != session[:prices].keys
    end

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

  def generate_csv
    csv_string = WatchList.generate_csv()
    send_data csv_string, :filename => "watch_list-#{Date.today.to_formatted_s(:ymd)}.csv", :type => 'text/csv'
  end

  def plot
   puts "echo plot.rt.snap('#{current_object.ticker.symbol}') | R --no-save"
    `echo "plot.rt.snap('#{current_object.ticker.symbol}')" | R --no-save`
    send_file File.join(RAILS_ROOT, 'Rplots.pdf')
  end

  def sort_order
    session[:watch_list_sort_order]
  end

  def sort_order=(str)
    session[:watch_list_sort_order] = str
  end

  def sort_by_time
    self.sort_order = 'open_crossed_at desc, price'
    render_js do |page|
      page.redirect_to :action => 'index'
    end
  end

  def sort_by_price
    self.sort_order = 'price, open_crossed_at desc'
    render_js do |page|
      page.redirect_to :action => 'index'
    end
  end
end

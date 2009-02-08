class TickersController < ApplicationController

  protect_from_forgery :except => [:index, :auto_complete_for_ticker_symbol]

  auto_complete_for :ticker, :symbol

  make_resourceful do
    publish :xml, :attributes => [ :symbol, { :listing => [:name] } ]
    actions :all

    before :save do
      current_object.symbol.upcase!
    end
  end

  def find
    symbol = params[:ticker][:symbol]
    @current_objects ||= current_model.paginate(:all, :conditions => "symbol LIKE '#{symbol}%'", :page => params[:page], :per_page => 30, :include => [ :exchange, :current_listing] , :order => 'symbol')
    render :action => :index
  end

  def current_objects()
    @current_objects ||= current_model.paginate(:all, :page => params[:page], :per_page => 30, :include => [ :exchange, :current_listing] , :order => 'symbol')
  end

  def plot_daily
  end

  def plot_live
  end

  def plot_histogram
  end

end

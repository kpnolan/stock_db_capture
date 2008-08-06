class TickersController < ApplicationController
  def index
    @tickers = Ticker.find(:all)
  end
  
  def show
    @ticker = Ticker.find(params[:id])
  end
  
  def new
    @ticker = Ticker.new
  end
  
  def create
    @ticker = Ticker.new(params[:ticker])
    if @ticker.save
      flash[:notice] = "Successfully created ticker."
      redirect_to @ticker
    else
      render :action => 'new'
    end
  end
  
  def edit
    @ticker = Ticker.find(params[:id])
  end
  
  def update
    @ticker = Ticker.find(params[:id])
    if @ticker.update_attributes(params[:ticker])
      flash[:notice] = "Successfully updated ticker."
      redirect_to @ticker
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @ticker = Ticker.find(params[:id])
    @ticker.destroy
    flash[:notice] = "Successfully destroyed ticker."
    redirect_to tickers_url
  end
end

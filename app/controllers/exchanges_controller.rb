class ExchangesController < ApplicationController
  def index
    @exchanges = Exchange.find(:all)
  end
  
  def show
    @exchange = Exchange.find(params[:id])
  end
  
  def new
    @exchange = Exchange.new
  end
  
  def create
    @exchange = Exchange.new(params[:exchange])
    if @exchange.save
      flash[:notice] = "Successfully created exchange."
      redirect_to @exchange
    else
      render :action => 'new'
    end
  end
  
  def edit
    @exchange = Exchange.find(params[:id])
  end
  
  def update
    @exchange = Exchange.find(params[:id])
    if @exchange.update_attributes(params[:exchange])
      flash[:notice] = "Successfully updated exchange."
      redirect_to @exchange
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @exchange = Exchange.find(params[:id])
    @exchange.destroy
    flash[:notice] = "Successfully destroyed exchange."
    redirect_to exchanges_url
  end
end

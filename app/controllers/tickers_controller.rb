class TickersController < ApplicationController
  make_resourceful do
    actions :all
  end

  def current_objects()
    @current_objects ||= Ticker.find(:all, :include => [ :exchange, :listing] , :order => 'symbol')
  end
end

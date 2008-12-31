class LiveQuotesController < ApplicationController
  make_resourceful do
    actions :all
    belongs_to :ticker
  end
  def current_objects()
    @current_objects ||= current_model.paginate(:all, :page => params[:page], :per_page => 60, :order => 'symbol, last_trade_time')
  end
end

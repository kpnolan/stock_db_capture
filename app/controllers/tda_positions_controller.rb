class TdaPositionsController < ApplicationController

  helper_method :watch_list_tda_positions_path

  make_resourceful do
    belongs_to :watch_list
    actions :all

    before :new do
      wl = WatchList.find params['watch_list_id']
      current_object.ticker_id = wl.ticker_id
      current_object.entry_date = Date.today
      current_object.entry_price = wl.price
    end

    before :create do
      params['tda_position']['ticker_id'] = current_object.ticker_id.to_s
    end
  end

  def singular?
    true
  end

  def watch_list_tda_positions_path(obj)
    tda_positions_path
  end

end

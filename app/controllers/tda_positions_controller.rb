class TdaPositionsController < ApplicationController

  helper_method :watch_list_tda_positions_path

  make_resourceful do
    belongs_to :watch_list
    actions :all

    after :create do
      #only set the opened_on field when the record is created since it's used to descriminate which watch list is appears on
      current_object.watch_list.update_attribute(:opened_on, Date.today)
    end
  end

  def new
    wl = WatchList.find params['watch_list_id']
    debugger
    @tda_position = returning(TdaPosition.new) do |obj|
      obj.watch_list_id = wl.id
      obj.ticker_id = wl.ticker_id
      obj.entry_date = Date.today
      obj.entry_price = wl.price
      obj.num_shares = (10000.0/wl.price).floor
    end
  end

  def watch_list_tda_positions_path(obj)
    tda_positions_path
  end

end

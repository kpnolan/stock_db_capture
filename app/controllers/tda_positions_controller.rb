class TdaPositionsController < ApplicationController

  helper_method :watch_list_tda_positions_path

  make_resourceful do
    belongs_to :watch_list
    actions :all

    before :new do
      debugger
    end
  end

  def new
    wl = WatchList.find params['watch_list_id']
    wl.update_attribute(:opened_on, Date.today)
    @tda_position = returning(TdaPosition.new) do |obj|
      obj.watch_list_id = wl.id
      obj.ticker_id = wl.ticker_id
      obj.entry_date = Date.today
      obj.entry_price = wl.price
      obj.num_shares = 10000
    end
  end

  def watch_list_tda_positions_path(obj)
    tda_positions_path
  end

end

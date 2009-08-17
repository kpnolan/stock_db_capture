module WatchListsHelper

  def price_color(watch_list)
    if session[:prices][watch_list.ticker_id].nil? or session[:prev_prices][watch_list.ticker_id].nil?
      'green'
    else
      session[:prices][watch_list.ticker_id] >= session[:prev_prices][watch_list.ticker_id] ? 'green' : 'red'
    end
  end

  def watch_lists_path
    objects_path
  end

  def watch_list_path(obj)
    object_path(obj)
  end
end

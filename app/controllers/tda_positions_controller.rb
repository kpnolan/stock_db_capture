module Resourceful
  module Default
    module Actions
      # GET /tda_positions/12/edit
      def close
        load_object
        before :close
        response_for :close
      end
      # PUT /tda_positions/12
      def closed
        load_object
        before :closed
        if current_object.update_attributes object_parameters
          save_succeeded!
          after :closed
          response_for :update
        else
          save_failed!
          after :update_fails
          response_for :update_fails
        end
      end
    end
  end
end

class TdaPositionsController < ApplicationController

  extend TradingCalendar

  helper_method :watch_list_tda_positions_path

  make_resourceful do
    belongs_to :watch_list
    actions :all

    before :index do
      TdaPosition.synchronize_with_watch_list()
    end

    after :update do
      unless current_object.exit_price.blank?
        days_held = TdaPositionsController.trading_days_between(opened_at, closed_at)
        current_object.update_attributes!(:days_held => days_held, :exit_date => closed_at.to_date)
      end
    end

    after :create do
      #only set the opened_on field when the record is created since it's used to descriminate which watch list is appears on
      current_object.watch_list.update_attributes!(:opened_on => Date.today, :rsi_target_price => nil, :rvi_target_price => nil)
    end

    before :close do
      tda = current_object
      tda.exit_date = Date.today
      tda.exit_price = tda.curr_price = tda.watch_list.price
      tda.days_held = TdaPositionsController.trading_day_count(tda.entry_date, tda.exit_date)
      tda.rreturn = tda.roi()
      tda.nreturn = tda.rreturn / tda.days_held
    end
  end

  def new
    wl = WatchList.find params['watch_list_id']
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

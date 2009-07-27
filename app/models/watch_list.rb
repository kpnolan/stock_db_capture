# == Schema Information
# Schema version: 20090726180014
#
# Table name: watch_list
#
#  id              :integer(4)      not null, primary key
#  ticker_id       :integer(4)
#  tda_position_id :integer(4)
#  target_price    :float
#  target_ival     :float
#  curr_price      :float
#  curr_ival       :float
#  predicted_price :float
#  predicted_ival  :float
#  crossed_at      :datetime
#  updated_at      :datetime
#  predicted_sd    :float
#

class WatchList < ActiveRecord::Base
  set_table_name 'watch_list'

  belongs_to :tda_position
  belongs_to :ticker

  class << self
    def create_openning(ticker_id, target_price, target_ivalue)
      create!(:ticker_id => ticker_id, :target_price => target_price, :target_ival => target_ival)
    end
    def create_closure(position, target_price, target_ivalue)
      create!(:ticker_id => position.ticker_id, :tda_poistion_id => position[:id], :target_price => target_price, :target_ival => target_ival)
    end
  end

  def update(curr_price, curr_ival, predicted_price, predicted_ival, stddev, time)
    update_attributes!(:curr_price => curr_price, :curr_ival => curr_ival,
                       :predicted_price => predicted_price, :predicted_ival => predicted_ival, :predicted_sd => stddev,
                       :updated_at => time)
  end

  def crossing(curr_price, curr_ival, time)
    update_attributes!(:curr_price => curr_price, :curr_ival => curr_ival, :updated_at => time, :crossed_at => time)
  end
end

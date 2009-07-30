# == Schema Information
# Schema version: 20090729181214
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
#  last_snaptime   :datetime
#  predicted_sd    :float
#  num_samples     :integer(4)
#  snapshots_above :integer(4)      default(0), not null
#  snapshots_below :integer(4)      default(0), not null
#

class WatchList < ActiveRecord::Base
  set_table_name 'watch_list'

  belongs_to :tda_position
  belongs_to :ticker

  class << self
    def create_openning(ticker_id, target_price, current_ival, target_ivalue)
      create!(:ticker_id => ticker_id, :target_price => target_price, :curr_ival => current_ival, :target_ival => target_ivalue)
    end
    def create_closure(position, target_price, target_ivalue)
      create!(:ticker_id => position.ticker_id, :tda_poistion_id => position[:id], :target_price => target_price, :target_ival => target_ival)
    end

    def lookup_entry(ticker_id, threshold)
      find(:first, :conditions => { :ticker_id => ticker_id, :target_ival => threshold})
    end
  end

  def update_from_snapshot!(curr_price, curr_ival, num_samples, predicted_price, predicted_ival, stddev, snap_time)
    attrs = { :curr_price => curr_price, :curr_ival => curr_ival, :num_samples => num_samples,
              :predicted_price => predicted_price, :predicted_ival => predicted_ival, :predicted_sd => stddev,
              :last_snaptime => snap_time }
    attrs[:crossed_at] = snap_time if curr_ival >= self.target_ival
    increment :snapshots_above if curr_ival >= self.target_ival
    increment :snapshots_below if curr_ival <  self.target_ival
    update_attributes!(attrs)
  end
end

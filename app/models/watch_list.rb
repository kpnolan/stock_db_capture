# == Schema Information
# Schema version: 20090810235140
#
# Table name: watch_list
#
#  id              :integer(4)      not null, primary key
#  ticker_id       :integer(4)
#  tda_position_id :integer(4)
#  target_price    :float
#  target_ival     :float
#  price           :float
#  curr_ival       :float
#  predicted_price :float
#  crossed_at      :datetime
#  last_snaptime   :datetime
#  predicted_sd    :float
#  num_samples     :integer(4)
#  snapshots_above :integer(4)      default(0), not null
#  snapshots_below :integer(4)      default(0), not null
#  entered_on      :date
#  closed_on       :date
#  open            :float
#  high            :float
#  low             :float
#  close           :float
#  volume          :integer(4)
#  last_seq        :integer(4)
#

class WatchList < ActiveRecord::Base
  set_table_name 'watch_list'

  belongs_to :tda_position
  belongs_to :ticker

  validates_presence_of :ticker_id
  validates_uniqueness_of :ticker_id, :scope => :target_ival

  class << self
    def create_openning(ticker_id, target_price, current_ival, target_ivalue, open_date)
      unless lookup_entry(ticker_id, open_date)
        create!(:ticker_id => ticker_id, :target_price => target_price, :curr_ival => current_ival, :target_ival => target_ivalue, :entered_on => open_date)
      end
    end

    def create_closure(position, target_price, target_ivalue, close_date)
      create!(:ticker_id => position.ticker_id, :tda_poistion_id => position[:id], :target_price => target_price, :target_ival => target_ival, :closed_on => close_date)
    end

    def lookup_entry(ticker_id, entry_date=nil)
      cond = { :ticker_id => ticker_id }
      cond.merge!(:entered_on => entry_date) unless entry_date.nil?
      find(:first, :conditions => cond)
    end
  end

  def update_from_snapshot!(last_bar, curr_ival, num_samples, predicted_price, stddev, last_seq)
    price = last_bar.delete :close
    snap_time = last_bar.delete :time
    attrs = { :price => price, :curr_ival => curr_ival, :num_samples => num_samples,
              :predicted_price => predicted_price, :predicted_sd => stddev, :last_snaptime => snap_time, :last_seq => last_seq }
    attrs[:crossed_at] = snap_time  if self.crossed_at.nil? and curr_ival >= self.target_ival
    increment :snapshots_above  if self.crossed_at and curr_ival >= self.target_ival
    increment :snapshots_below  if self.crossed_at and curr_ival <  self.target_ival
    update_attributes!(attrs.merge(last_bar))
  end
end

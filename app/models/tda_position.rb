# == Schema Information
# Schema version: 20090726180014
#
# Table name: tda_positions
#
#  id           :integer(4)      not null, primary key
#  ticker_id    :integer(4)
#  estrategy_id :integer(4)
#  xstrategy_id :integer(4)
#  entry_price  :float
#  exit_price   :float
#  curr_price   :float
#  entry_date   :date
#  exit_date    :date
#  rum_shares   :integer(4)
#  days_held    :integer(4)
#  stop_loss    :boolean(1)
#  nreturn      :float
#  rretrun      :float
#  eorderid     :integer(4)
#  xorderid     :integer(4)
#  openned_at   :datetime
#  closed_at    :datetime
#  updated_at   :datetime
#  com          :boolean(1)
#

class TdaPosition < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :strategy, :foreign_key => :estrategy_id
  belongs_to :strategy, :foreign_key => :xstrategy_id

  def update_price(current_price)
    update_attribute(:curr_price, current_price)
  end
  
  def close(price, time)
  end
end

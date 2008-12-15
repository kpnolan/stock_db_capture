# == Schema Information
# Schema version: 20080813192644
#
# Table name: daily_returns
#
#  id              :integer(4)      not null, primary key
#  volume          :integer(4)
#  ask             :float
#  bid             :float
#  day_range_low   :float
#  day_range_high  :float
#  change_percent  :float
#  last_trade_date :date
#  tickertrend     :string(7)
#  change_points   :float
#  open            :float
#  previous_close  :float
#  last_trade      :float
#  avg_volumn      :integer(4)
#  day_low         :float
#  last_trade_time :datetime
#  day_high        :float
#  ticker_id       :integer(4)
#  created_at      :datetime
#  updated_at      :datetime
#

class DailyReturn < ActiveRecord::Base
  belongs_to :ticker

  def symbol=(value)
  end

end

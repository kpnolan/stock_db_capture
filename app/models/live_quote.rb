# == Schema Information
# Schema version: 20081227180640
#
# Table name: live_quotes
#
#  id              :integer(4)      not null, primary key
#  volume          :integer(4)
#  change_percent  :float
#  change_points   :float
#  last_trade      :float
#  last_trade_time :datetime
#  ticker_id       :integer(4)
#

class LiveQuote < ActiveRecord::Base
  belongs_to :ticker

  def symbol=(value)
  end

  def self.order
    'last_trade_time, id'
  end

  def self.time_col
    'last_trade_time'
  end

  extend TableExtract
  extend Aggregator

end

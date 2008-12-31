# == Schema Information
# Schema version: 20081230211500
#
# Table name: live_quotes
#
#  id              :integer(4)      not null, primary key
#  volume          :integer(4)
#  r               :float
#  change_points   :float
#  last_trade      :float
#  last_trade_time :datetime
#  ticker_id       :integer(4)
#  logr            :float
#

class LiveQuote < ActiveRecord::Base
  belongs_to :ticker

  def symbol=(value)
  end

  def last_trade_date=(value)
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

# == Schema Information
# Schema version: 20090218001147
#
# Table name: fast_live_quotes
#
#  ticker_id       :integer(4)
#  last_trade_time :datetime
#  last_trade      :float
#  volume          :integer(4)
#

class FastLiveQuote < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract
  extend Aggregator

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end
  def self.order ; 'last_trade_time, id'; end
  def self.time_col ; :last_trade_time ;  end
  def self.time_convert ; :to_time ;  end
  def self.time_class ; Time ;  end
  def self.time_res; 60; end
end

# == Schema Information
# Schema version: 20080813192644
#
# Table name: real_time_quotes
#
#  id              :integer(4)      not null, primary key
#  last_trade      :float
#  ask             :float
#  bid             :float
#  last_trade_time :datetime
#  change          :float
#  change_points   :float
#  ticker_id       :integer(4)
#  created_at      :datetime
#  updated_at      :datetime
#

class RealTimeQuote < ActiveRecord::Base
  belongs_to :ticker

  ATTRS = [ :bid, :ask, :change, :change_points, :last_trade ]

  def self.default_attrs()
    ATTRS
  end

  def self.order
    'last_trade_time, id'
  end

  extend TableExtract

end

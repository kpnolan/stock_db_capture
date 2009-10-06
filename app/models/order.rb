# == Schema Information
# Schema version: 20090924181907
#
# Table name: orders
#
#  id               :integer(4)      not null, primary key
#  txn              :string(3)       not null
#  type             :string(3)       not null
#  expiration       :string(3)       not null
#  quantity         :integer(4)
#  placed_at        :datetime
#  filled_at        :datetime
#  activation_price :float
#  order_price      :float
#  fill_price       :float
#  ticker_id        :integer(4)      not null
#  position_id      :integer(4)
#  sim_position_id  :integer(4)
#

class Order < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :position

  TXN_TYPE = [ :buy, :sel, :btc, :ss ]
  ORDER_TYPE = [ :mkt, :lmt, :stm, :stl ]
  EXPIRATION = [ :day, :gtc ]

end

# == Schema Information
# Schema version: 20080813192644
#
# Table name: daily_closes
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)      not null
#  date      :date
#  open      :float
#  close     :float
#  high      :float
#  low       :float
#  adj_close :float
#  volume    :integer(4)
#  week      :integer(4)
#  month     :integer(4)
#

class DailyClose < ActiveRecord::Base
  belongs_to :ticker
end

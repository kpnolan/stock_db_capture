# == Schema Information
# Schema version: 20081227180640
#
# Table name: aggregations
#
#  id           :integer(4)      not null, primary key
#  ticker_id    :integer(4)      not null
#  date         :date
#  open         :float
#  close        :float
#  high         :float
#  low          :float
#  adj_close    :float
#  volume       :integer(4)
#  week         :integer(4)
#  month        :integer(4)
#  sample_count :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

class Aggregation < ActiveRecord::Base
  belongs_to :ticker
end

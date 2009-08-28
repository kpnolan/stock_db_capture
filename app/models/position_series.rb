# == Schema Information
# Schema version: 20090826144841
#
# Table name: position_series
#
#  id           :integer(4)      not null, primary key
#  position_id  :integer(4)
#  indicator_id :integer(4)
#  date         :date
#  value        :float
#

class PositionSeries < ActiveRecord::Base
  belongs_to :position
  belongs_to :indicator
end

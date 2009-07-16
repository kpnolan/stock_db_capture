# == Schema Information
# Schema version: 20090711171320
#
# Table name: position_stats
#
#  id          :integer(4)      not null, primary key
#  position_id :integer(4)
#  name        :string(255)
#  value       :float
#

class PositionStats < ActiveRecord::Base
end

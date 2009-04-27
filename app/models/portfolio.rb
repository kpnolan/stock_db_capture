# == Schema Information
# Schema version: 20090425175412
#
# Table name: portfolios
#
#  id            :integer(4)      not null, primary key
#  name          :string(255)
#  initial_value :float
#  created_at    :datetime
#  updated_at    :datetime
#

class Portfolio < ActiveRecord::Base
  has_many :positions
end

# == Schema Information
# Schema version: 20090618213332
#
# Table name: indicators
#
#  id   :integer(4)      not null, primary key
#  name :string(255)
#

class Indicator < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
end

# == Schema Information
# Schema version: 20090707232154
#
# Table name: indicators
#
#  id   :integer(4)      not null, primary key
#  name :string(255)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Indicator < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
end

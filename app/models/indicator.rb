# == Schema Information
# Schema version: 20091029212126
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

  class << self
    def lookup(name)
      obj = find(:first, :conditions => { :name => name.to_s })
      raise ActiveRecord::RecordNotFound, "no indicator named: '#{name}' found" if obj.nil?
      obj
    end
  end
end

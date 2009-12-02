# == Schema Information
# Schema version: 20091125220250
#
# Table name: derived_value_types
#
#  id   :integer(4)      not null, primary key
#  name :string(255)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class DerivedValueType < ActiveRecord::Base
  has_many :derived_values
end

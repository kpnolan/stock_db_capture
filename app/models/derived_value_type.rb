# == Schema Information
# Schema version: 20090621183035
#
# Table name: derived_value_types
#
#  id   :integer(4)      not null, primary key
#  name :string(255)
#

class DerivedValueType < ActiveRecord::Base
  has_many :derived_values
end

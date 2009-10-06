# == Schema Information
# Schema version: 20090924181907
#
# Table name: derived_values
#
#  id                    :integer(4)      not null, primary key
#  ticker_id             :integer(4)
#  derived_value_type_id :integer(4)
#  date                  :date
#  time                  :datetime
#  value                 :float
#

class DerivedValue < ActiveRecord::Base
  belongs_to :derived_value_type
end

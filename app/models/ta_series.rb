# == Schema Information
# Schema version: 20090719170151
#
# Table name: ta_series
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)
#  ta_spec_id :integer(4)
#  stime      :datetime
#  value      :float
#

class TaSeries < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :ta_spec
end

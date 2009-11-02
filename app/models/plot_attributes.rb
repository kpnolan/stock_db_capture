# == Schema Information
# Schema version: 20091029212126
#
# Table name: plot_attributes
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  ticker_id   :integer(4)
#  type        :string(255)
#  anchor_date :datetime
#  period      :integer(4)
#  attributes  :string(255)
#

class PlotAttributes < ActiveRecord::Base
end

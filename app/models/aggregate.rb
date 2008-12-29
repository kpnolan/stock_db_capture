# == Schema Information
# Schema version: 20081228175347
#
# Table name: aggregates
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  date      :date
#  start     :datetime
#  open      :float
#  close     :float
#  high      :float
#  low       :float
#  volume    :integer(4)
#  period    :integer(4)
#

class Aggregate < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract

  def self.order
    'start'
  end

end

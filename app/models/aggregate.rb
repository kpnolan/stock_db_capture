# == Schema Information
# Schema version: 20090425175412
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
#  r         :float
#  logr      :float
#

class Aggregate < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract
  extend Plot

  def self.order ; 'start'; end
  def self.time_col ; :start ;  end
  def self.time_convert ; :to_time ;  end
  def self.time_class ; Time ;  end
  def self.time_res; [ 15.minutes.seconds ]; end

end

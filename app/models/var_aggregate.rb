# == Schema Information
# Schema version: 20090506055841
#
# Table name: var_aggregates
#
#  id           :integer(4)      not null, primary key
#  ticker_id    :integer(4)
#  date         :date
#  start        :datetime
#  open         :float
#  close        :float
#  high         :float
#  low          :float
#  volume       :integer(4)
#  period       :integer(4)
#  r            :float
#  logr         :float
#  sample_count :integer(4)
#

class VarAggregate < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract
  extend Plot

  def self.order ; 'start'; end
  def self.time_col ; :start ;  end
  def self.time_convert ; :to_time ;  end
  def self.time_class ; Time ;  end
  def self.time_res; [ 5.minutes ]; end

end

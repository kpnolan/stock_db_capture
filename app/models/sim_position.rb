# == Schema Information
# Schema version: 20090924181907
#
# Table name: sim_positions
#
#  id          :integer(4)      not null, primary key
#  entry_date  :datetime
#  exit_date   :datetime
#  quantity    :integer(4)
#  entry_price :float
#  exit_price  :float
#  nreturn     :float
#  roi         :float
#  days_held   :integer(4)
#  eorder_id   :integer(4)
#  xorder_id   :integer(4)
#  ticker_id   :integer(4)
#  position_id :integer(4)
#

class SimPosition < ActiveRecord::Base
  belongs_to :eorder, :class_name => 'Order'
  belongs_to :xorder, :class_name => 'Order'
  belongs_to :ticker
  belongs_to :position

  class << self
    def open_position_count()
      count(:conditions => { :exit_date => nil} )
    end

    def expiring_positions(date)
      find(:all, :include => :position, :conditions => ['positions.exit_date = ?', date] )
    end
  end
end

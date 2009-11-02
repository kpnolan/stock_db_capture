# == Schema Information
# Schema version: 20091029212126
#
# Table name: sim_summaries
#
#  id                  :integer(4)      not null, primary key
#  sim_date            :date
#  positions_held      :integer(4)
#  positions_available :integer(4)
#  portfolio_value     :float
#  cash_balance        :float
#

class SimSummary < ActiveRecord::Base
  class << self
    def truncate()
      connection.execute("truncate #{self.to_s.tableize}")
    end
  end
end

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
#  pos_opened          :integer(4)
#  pos_closed          :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class SimSummary < ActiveRecord::Base

  validates_presence_of :sim_date, :positions_held, :positions_available, :portfolio_value, :cash_balance, :pos_opened, :pos_closed
  validates_numericality_of :positions_held, :positions_available, :portfolio_value, :cash_balance, :pos_opened, :pos_closed

  class << self
    def truncate()
      connection.execute("truncate #{table_name}")
    end
  end

  def event_time
    sim_date
  end

  def to_s()
    format('Pval: %7.0f Cval: %7.0f Total: %7.0f', portfolio_value, cash_balance, portfolio_value + cash_balance)
  end
end

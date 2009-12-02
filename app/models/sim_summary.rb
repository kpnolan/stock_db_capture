# == Schema Information
# Schema version: 20091125220250
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

  # to insert a comma every 3 digits do: n.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
  def to_s()
    pretty_portfolio_value = portfolio_value.round.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    pretty_cash_balance = cash_balance.round.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    pretty_total = (portfolio_value + cash_balance).round.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    format(' $%10s + $%10s = $%10s', pretty_portfolio_value, pretty_cash_balance, pretty_total)
  end
end

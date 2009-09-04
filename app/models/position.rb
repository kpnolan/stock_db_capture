# == Schema Information
# Schema version: 20090904191327
#
# Table name: positions
#
#  id                :integer(4)      not null, primary key
#  ticker_id         :integer(4)
#  entry_date        :datetime
#  exit_date         :datetime
#  entry_price       :float
#  exit_price        :float
#  num_shares        :integer(4)
#  stop_loss         :boolean(1)
#  days_held         :integer(4)
#  nreturn           :float
#  scan_id           :integer(4)
#  logr              :float
#  short             :boolean(1)
#  entry_pass        :integer(4)
#  indicator_id      :integer(4)
#  roi               :float
#  closed            :boolean(1)
#  entry_strategy_id :integer(4)
#  exit_strategy_id  :integer(4)
#

#require 'rubygems'
#require 'ruby-debug'

class Position < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :entry_strategy
  belongs_to :exit_strategy
  belongs_to :scan
  belongs_to :indicator

  has_many :position_series, :dependent => :delete_all

  extend TradingCalendar

  def return()
    unless exit_price.nil?
      ((exit_price - entry_price) / entry_price)*100.0
    else
      '-999.99'
    end
  end

  def self.open(ticker, entry_strategy, exit_strategy, scan, entry_time, entry_price, pass, options={})

    begin
      short = options[:short]
      pos = create!(:ticker_id => ticker.id,
                    :entry_strategy_id => entry_strategy[:id], :exit_strategy_id => exit_strategy[:id], :scan_id => scan[:id],
                    :entry_price => entry_price, :entry_date => entry_time, :num_shares => 1,
                    :short => short, :entry_pass => pass)
    rescue ActiveRecord::RecordInvalid => e
      raise e.class, "You have a duplicate record (mostly likely you need to do a truncate of the old strategy) " if e.to_s =~ /already been taken/
      raise e
    end
    pos
  end
end

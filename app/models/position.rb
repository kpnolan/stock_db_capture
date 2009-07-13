# == Schema Information
# Schema version: 20090707232154
#
# Table name: positions
#
#  id            :integer(4)      not null, primary key
#  ticker_id     :integer(4)
#  entry_date    :datetime
#  exit_date     :datetime
#  entry_price   :float
#  exit_price    :float
#  num_shares    :integer(4)
#  stop_loss     :string(255)
#  strategy_id   :integer(4)
#  days_held     :integer(4)
#  nreturn       :float
#  scan_id       :integer(4)
#  entry_trigger :float
#  exit_trigger  :float
#  logr          :float
#  short         :boolean(1)
#  pass          :integer(4)
#  entry_pass    :integer(4)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

#require 'rubygems'
#require 'ruby-debug'

class Position < ActiveRecord::Base

  extend TradingCalendar

  belongs_to :ticker
  has_and_belongs_to_many :strategies

  def self.open(population, strategy, ticker, entry_time, entry_price, entry_trigger, short=false, pass=0, aux={})
    pos = create!(:scan_id => population.id, :strategy_id => strategy.id, :ticker_id => ticker.id,
            :entry_price => entry_price, :entry_date => entry_time, :num_shares => 1, :entry_trigger => entry_trigger,
            :short => short, :entry_pass => pass)
    unless aux.empty?
      aux.delete :index
      aux.each do |k,v|
        PositionStats.create!(:position_id => pos.id, :name => k.to_s, :value => v)
      end
    end
    pos
  end
end

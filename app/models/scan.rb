# == Schema Information
# Schema version: 20090403161440
#
# Table name: scans
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  start_date  :date
#  end_date    :date
#  conditions  :text
#  description :string(255)
#

class Scan < ActiveRecord::Base

  has_and_belongs_to_many :tickers

  validates_uniqueness_of :name
  validates_presence_of :name, :start_date, :end_date, :conditions

  before_save :clear_associations_if_dirty

  def clear_associations_if_dirty
    tickers.clear if changed?
  end

  def tickers_ids(repopulate=false)
    sql = "SELECT ticker_id FROM daily_closes WHERE " +
          "date >= '#{start_date.to_s(:db)}' AND date <= '#{end_date.to_s(:db)}' " +
          "GROUP BY ticker_id " +
          "HAVING #{conditions}"
    if repopulate || tickers.empty?
      tickers.clear
      @population = Scan.connection.select_values(sql)
      self.ticker_ids = @population
      ticker_ids
    else
      ticker_ids
    end
  end
end

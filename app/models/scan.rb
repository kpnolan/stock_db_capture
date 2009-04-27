# == Schema Information
# Schema version: 20090425175412
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
  has_and_belongs_to_many :positions

  validates_uniqueness_of :name
  validates_presence_of :name, :start_date, :end_date, :conditions

  before_save :clear_associations_if_dirty

  def self.find_by_name(keyword_or_string)
    first(:conditions => { :name => keyword_or_string.to_s.downcase})
  end

  def clear_associations_if_dirty
    tickers.clear if changed?
  end

  # TODO find a better name for this method
  def tickers_ids(repopulate=false)
    sql = "SELECT ticker_id FROM daily_closes WHERE " +
          "date >= '#{start_date.to_s(:db)}' AND date <= '#{end_date.to_s(:db)}' " +
          "GROUP BY ticker_id " +
          "HAVING #{conditions}"
    if repopulate || tickers.empty?
      puts "Performing #{name} scan because it is not be done before or criterion have changed"
      tickers.clear
      @population_ids = Scan.connection.select_values(sql)
      self.ticker_ids = @population_ids
      ticker_ids
    else
      puts "Using cached values for scan #{name}"
      ticker_ids
    end
  end
end
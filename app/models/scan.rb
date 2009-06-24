# == Schema Information
# Schema version: 20090621183035
#
# Table name: scans
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  start_date  :date
#  end_date    :date
#  conditions  :text
#  description :string(255)
#  join        :string(255)
#

class Scan < ActiveRecord::Base

  has_and_belongs_to_many :tickers
  has_and_belongs_to_many :strategies

  validates_uniqueness_of :name
  validates_presence_of :name, :start_date, :end_date

  before_save :clear_associations_if_dirty

  def self.find_by_name(keyword_or_string)
    first(:conditions => { :name => keyword_or_string.to_s.downcase})
  end

  def clear_associations_if_dirty
    tickers.clear if changed?
    strategies.clear if changed?
  end

  def population_ids(repopulate=false)
    tickers_ids(repopulate)
  end

  # TODO find a better name for this method
  def tickers_ids(repopulate=false)
    join = self.join ? self.join : ''
    having = conditions ? "HAVING #{conditions}" : ''
    sql = "SELECT daily_bars.ticker_id FROM daily_bars #{join} WHERE " +
          "date >= '#{start_date.to_s(:db)}' AND date <= '#{end_date.to_s(:db)}' " +
          "GROUP BY ticker_id " + having
    if repopulate || tickers.empty?
      $logger.info "Performing #{name} scan because it is not be done before or criterion have changed" if $logger
      tickers.clear
      @population_ids = Scan.connection.select_values(sql)
      self.ticker_ids = @population_ids
      ticker_ids
    else
      $logger.info "Using *CACHED* values for scan #{name}"
      ticker_ids
    end
  end
end

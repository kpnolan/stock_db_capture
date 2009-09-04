# == Schema Information
# Schema version: 20090904191327
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
#  table_name  :string(255)
#  order_by    :string(255)
#  prefetch    :integer(4)
#

class Scan < ActiveRecord::Base

  include TradingCalendar

  has_many :positions, :dependent => :destroy
  has_and_belongs_to_many :tickers
  has_and_belongs_to_many :entry_strategies

  validates_uniqueness_of :name
  validates_presence_of :name, :start_date, :end_date

  before_save :clear_associations_if_dirty

  class << self
    def find_by_name(keyword_or_string)
      first(:conditions => { :name => keyword_or_string.to_s.downcase})
    end
  end

  def clear_associations_if_dirty
    tickers.clear if changed?
    entry_strategies.clear if changed?
  end

  def population_ids(repopulate=false)
    tickers_ids(repopulate)
  end

  def adjusted_start()
    prefetch.is_a?(Numeric) ? trading_date_from(start_date, -prefetch.to_i) : start_date
  end

  # TODO find a better name for this method
  def tickers_ids(repopulate=false)
    count = "count(*) = #{total_bars(adjusted_start, end_date)}"
    order = self.order_by ? " ORDER BY #{self.order_by}" : ''
    having = conditions ? "HAVING #{conditions} and #{count}" : "HAVING #{count}"

    sql = "SELECT #{table_name}.ticker_id FROM #{table_name} #{join} WHERE " +
          "date(bartime) BETWEEN '#{adjusted_start.to_s(:db)}' AND '#{end_date.to_s(:db)}' " +
          "GROUP BY ticker_id " + having + order
    if repopulate || tickers.empty?
      $logger.info "Performing #{name} scan because it is not be done before or criterion have changed" if $logger
      tickers.delete_all
      @population_ids = Scan.connection.select_values(sql)
      self.ticker_ids = @population_ids.map(&:to_i)
      ticker_ids
    else
      $logger.info "Using *CACHED* values for scan #{name}" if $logger
      ticker_ids
    end
  end

  def matching_ids(repopulate=false)

  end
end

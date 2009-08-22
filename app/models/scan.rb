# == Schema Information
# Schema version: 20090822010347
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

  has_and_belongs_to_many :tickers
  has_and_belongs_to_many :strategies

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
    strategies.clear if changed?
  end

  def population_ids(repopulate=false)
    tickers_ids(repopulate)
  end

  def adjusted_start()
    prefetch.is_a?(Numeric) ? trading_days_from(start_date, -prefetch.to_i).last : start_date
  end

  # TODO find a better name for this method
  def tickers_ids(repopulate=false)
    count = "count(*) = #{total_bars(adjusted_start, end_date)}"
    order = self.order_by ? " ORDER BY #{self.order_by}" : ''
    having = conditions ? "HAVING #{conditions} and #{count}" : "HAVING #{count}"
    debugger
    sql1 = "SELECT #{table_name}.ticker_id FROM #{table_name} #{join} WHERE " +
          "date >= '#{adjusted_start.to_s(:db)}' AND date <= '#{end_date.to_s(:db)}' " +
          "GROUP BY ticker_id " + having + order
    sql2 = "SELECT #{table_name}.ticker_id FROM #{table_name} #{join} WHERE " +
          "date(start_time) >= '#{adjusted_start.to_s(:db)}' AND date(start_time) <= '#{(end_date).to_s(:db)}' " +
          "GROUP BY ticker_id " + having + order
    if repopulate || tickers.empty?
      $logger.info "Performing #{name} scan because it is not be done before or criterion have changed" if $logger
      tickers.delete_all
      if table_name == 'daily_bars'
        debugger
        @population_ids = Scan.connection.select_values(sql1)
      elsif table_name == 'intra_day_bars'
        @population_ids = Scan.connection.select_values(sql2)
      else
        raise ArgumentError, 'table_name must be "daily_bar" or "intra_day_bars"'
      end
      self.ticker_ids = @population_ids.map(&:to_i)
      ticker_ids
    else
      $logger.info "Using *CACHED* values for scan #{name}" if $logger
      ticker_ids
    end
  end
end

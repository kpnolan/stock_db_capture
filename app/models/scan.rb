# == Schema Information
# Schema version: 20090729181214
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
#

class Scan < ActiveRecord::Base

  has_and_belongs_to_many :tickers
  has_and_belongs_to_many :strategies

  validates_uniqueness_of :name
  validates_presence_of :name, :start_date, :end_date

  before_save :clear_associations_if_dirty

  JOIN_CLAUSE = 'JOIN tickers ON tickers.id = ticker_id JOIN exchanges ON exchanges.id = exchange_id '

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

  # TODO find a better name for this method
  def tickers_ids(repopulate=false)
    join = self.join ? JOIN_CLAUSE + self.join : JOIN_CLAUSE
    order = self.order_by ? " ORDER BY #{self.order_by}" : ''
    having = conditions ? "HAVING #{conditions}" : ''
    sql1 = "SELECT #{table_name}.ticker_id FROM #{table_name} #{join} WHERE " +
          "date >= '#{start_date.to_s(:db)}' AND date <= '#{end_date.to_s(:db)}'AND exchanges.symbol <> 'PCX' " +
          "GROUP BY ticker_id " + having + order
    sql2 = "SELECT #{table_name}.ticker_id FROM #{table_name} #{join} WHERE " +
          "date(start_time) >= '#{start_date.to_s(:db)}' AND date(start_time) <= '#{(end_date).to_s(:db)}'AND exchanges.symbol <> 'PCX' " +
          "GROUP BY ticker_id " + having + order
    if repopulate || tickers.empty?
      $logger.info "Performing #{name} scan because it is not be done before or criterion have changed" if $logger
      tickers.clear
      if table_name == 'daily_bars'
        @population_ids = Scan.connection.select_values(sql1)
      elsif table_name == 'intra_day_bars'
        @population_ids = Scan.connection.select_values(sql2)
      else
        raise ArgumentError, 'table_name must be "daily_bar" or "intra_day_bars"'
      end
      self.ticker_ids = @population_ids
      ticker_ids
    else
      $logger.info "Using *CACHED* values for scan #{name}" if $logger
      ticker_ids
    end
  end
end

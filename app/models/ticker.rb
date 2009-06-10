# == Schema Information
# Schema version: 20090608195510
#
# Table name: tickers
#
#  id          :integer(4)      not null, primary key
#  symbol      :string(8)
#  exchange_id :string(255)
#  active      :boolean(1)
#  rety_count  :integer(4)      default(0)
#  name        :string(255)
#  locked      :boolean(1)
#  etf         :boolean(1)
#  sector_id   :integer(4)
#  industry_id :integer(4)
#

class Ticker < ActiveRecord::Base
  belongs_to :exchange
  has_one  :current_listing,    :dependent => :destroy
  has_many :daily_bars,         :dependent => :protect
  has_many :intrday_bars,       :dependent => :protect
  has_many :positions,          :dependent => :protect

  validates_presence_of :symbol

  has_and_belongs_to_many :scans

  def last_close
    DailyBar.connection.select_value("select adj_close from daily_bars where ticker_id = #{id} having max(date)").to_f
  end

  def listing
    current_listing
  end

  def self.lookup(symbol)
    find(:first, :conditions => { :symbol => symbol.to_s.upcase })
  end

  def self.listing_name(symbol)
    (ticker = find_by_symbol(symbol.to_s.upcase)) && ticker.name
  end

  def self.symbols
    self.connection.select_values('SELECT symbol FROM tickers ORDER BY symbol')
  end

  def self.active_symbols
    self.connection.select_values('SELECT symbol FROM tickers WHERE active = 1 ORDER BY symbol')
  end

  def self.active_ids
    self.connection.select_values('SELECT id FROM tickers WHERE active = 1 ORDER BY symbol')
  end

  def self.ids
    self.connection.select_values('SELECT symbol FROM tickers order by id').collect!(&:to_i)
  end

  def self.id_groups(count)
    ids = Ticker.connection.select_values('select id from tickers order by id').collect!(&:to_i)
    ids.in_groups_of(ids.length/count)
  end

  def self.lname(symbol)
    t = find_by_symbol(symbol.to_s.upcase)
    t.current_listing.name.split(' ').collect(&:capitalize).join(' ') if t && t.current_listing
  end
end

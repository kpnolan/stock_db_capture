# == Schema Information
# Schema version: 20100205165537
#
# Table name: tickers
#
#  id          :integer(4)      not null, primary key
#  symbol      :string(8)
#  exchange_id :integer(4)
#  active      :boolean(1)
#  retry_count :integer(4)      default(0)
#  name        :string(255)
#  locked      :boolean(1)
#  etf         :boolean(1)
#  sector_id   :integer(4)
#  industry_id :integer(4)
#  delisted    :boolean(1)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Ticker < ActiveRecord::Base
  belongs_to :exchange
  belongs_to :sector
  belongs_to :industry
  has_one  :current_listing,    :dependent => :destroy
  has_many :daily_bars,         :dependent => :protect
  has_many :intrday_bars,       :dependent => :protect
  has_many :positions,          :dependent => :protect
  has_many :splits,             :dependent => :protect

  validates_presence_of :symbol

  has_and_belongs_to_many :scans

  def last_close
    DailyBar.connection.select_value("select adj_close from daily_bars where ticker_id = #{id} having max(date)").to_f
  end

  def listing
    current_listing
  end

  class << self

    def exchange(symbol_or_id)
      if symbol_or_id.is_a?(Fixnum)
        ticker = find symbol_or_id
      else
        ticker = lookup(symbol_or_id)
      end

      case ticker.exchange.symbol
      when 'NCM', 'NGM','NasdaqNM'  then :nasdaq
      when 'AMX', 'NYSE'            then :nyse
      when 'PCX'                    then :pcx
      else
        raise ArgumenttError, "Cannot find exchange for #{ticker.symbol}"
      end
    end

    def resolve_id(ticker_or_sym)
      #FIXME return actual AR here, not id
      begin
        case ticker_or_sym
        when Numeric          then find(ticker_or_sym).id
        when Symbol, String   then lookup(ticker_or_sym).id
        when Ticker           then ticker_or_sym.id
        end
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end



    def lookup(symbol)
      ticker = find(:first, :conditions => { :symbol => symbol.to_s.upcase })
      raise ActiveRecord::RecordNotFound, "Couldn't find Ticker with symbol=#{symbol}" if ticker.nil?
      ticker
    end

    def listing_name(symbol)
      (ticker = find_by_symbol(symbol.to_s.upcase)) && ticker.name
    end

    def symbols
      connection.select_values('SELECT symbol FROM tickers ORDER BY symbol')
    end

    def active_symbols
      connection.select_values('SELECT symbol FROM tickers WHERE active = 1 ORDER BY symbol')
    end

    def active_ids
      connection.select_values('SELECT id FROM tickers WHERE active = 1 ORDER BY symbol')
    end

    def ids
      connection.select_values('SELECT symbol FROM tickers order by id').collect!(&:to_i)
    end

    def id_groups(count)
      ids = Ticker.connection.select_values('select id from tickers order by id').collect!(&:to_i)
      ids.in_groups_of(ids.length/count)
    end

    def lname(symbol)
      t = find_by_symbol(symbol.to_s.upcase)
      t.current_listing.name.split(' ').collect(&:capitalize).join(' ') if t && t.current_listing
    end
  end
end

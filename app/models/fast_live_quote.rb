class FastLiveQuote < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract
  extend Aggregator

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end
  def self.order ; 'last_trade_time, id'; end
  def self.time_col ; :last_trade_time ;  end
  def self.time_convert ; :to_time ;  end
  def self.time_class ; Time ;  end
  def self.time_res; 60; end
end

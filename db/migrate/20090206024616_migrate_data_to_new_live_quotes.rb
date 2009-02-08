class MigrateDataToNewLiveQuotes < ActiveRecord::Migration
  def self.up
     for ticker in Ticker.find(:all, :conditions => { :active => true, :dormant => false })
       puts ticker.symbol
       for live_quote in LiveQuote.find(:all, :conditions => { :ticker_id => ticker.id }, :order => 'last_trade_time')
         attrs = LiveQuote.column_names.inject({}) { |h, n| h[n.to_sym] = live_quote.send(n); h}
         attrs.delete(:id)
         LiveQuote1.create!(attrs)
       end
     end
  end

  def self.down
  end
end

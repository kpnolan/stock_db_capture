namespace :active_trader do
  desc "Migrate LiveQuotes from InnoDB table to MyISAM table"
  task :migrate_live_quotes => :environment do
    for ticker in Ticker.find(:all, :conditions => { :active => true, :dormant => false }, :order => 'symbol')
      puts ticker.symbol
      for live_quote in LiveQuote.find(:all, :conditions => "ticker_id = #{ticker.id} AND last_trade_time > '2009-02-06 00:00:00'", :order => 'last_trade_time')
        attrs = LiveQuote.column_names.inject({}) { |h, n| h[n.to_sym] = live_quote.send(n); h}
        attrs.delete(:id)
        LiveQuote1.create!(attrs)
      end
    end
  end
end

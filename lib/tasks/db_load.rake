require 'populate_db'

namespace :db do
  namespace :load do

    desc "Load stock listings from yahoo"
    task :listings => :environment do

      # FIXME do a find or create on Listing instead
      Listing.delete_all
      Ticker.delete_all
      Exchange.delete_all

#      ActiveRecord::Base.transaction do
        ldr = TradingDBLoader.new(:exchange => Exchange, :ticker => Ticker, :listing => Listing)
        ldr.load('x')
#      end
    end
  end
end

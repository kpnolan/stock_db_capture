# Copyright © Kevin P. Nolan 2009 All Rights Reserved.
require 'rubygems'
require 'ruby-debug'
require 'faster_csv'

module Trading

  class StockWatcher

    include TradingCalendar

    WATCHLIST_NAME = 'Watchlist_2009'
    PREWATCH_NAME = 'Prewatch_2009'
    PRICE_CUTOFF_RATIO = 85.0/100.0
    RSI_OPEN_THRESHOLDS = [20.0, 25.0, 30.0]
    RSI_CUTOFF = 45.0

    attr_reader :candidate_ids, :scan, :qt, :logger, :closing_strategy_params

    def initialize(logger, options={})
      @logger = logger
      @closing_strategy_params = {
        :rsi => {:threshold => 50, :range => 0..100, :direction => :under, :result => :last},
        :rvi => {:threshold => 50, :range => 0..100, :direction => :under, :result => :last}
      }
    end

    def create_candidate_list()
      @scan = Scan.find_by_name(WATCHLIST_NAME)
      # We are looking back over the last month
      end_date = trading_date_from(Date.today, -1)
      start_date = trading_date_from(end_date, -20)
      liquid = 'min(volume) >= 75000 AND min(close) > 1.0'
      scan.update_attributes!(:table_name => 'daily_bars',
                              :start_date => start_date, :end_date => end_date,
                              :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                              :prefetch =>  nil,
                              :conditions => liquid)
      @candidate_ids = scan.population_ids()
    end

    def purge()
      WatchList.purge()
    end

    def reset()
      purge_old_snapshots()
      purge_entry_list()
      create_candidate_list()
      add_possible_entries()
      update_exit_list()
    end

    def clear_watch_list
      # TODO delete vestigial watch list entries that have been closed or terminated
    end

    def purge_old_snapshots
      Snapshot.delete_all("date(bartime) < curdate()")
    end

    def length
      ots_hash.length
    end

    def retrieve_snapshots
      begin
        WatchList.all.map(&:symbol).any? { |symbol| qt.snapshot(symbol) > 0 }
      rescue SnapshotProtocolError
        logger.error("#{Time.now.to_s(:db)}: Snapshot server not ready")
        raise
      rescue Exception => e
        logger.error("#{Time.now.to_s(:db)}: #{e.to_s}")
      end
    end

    #
    # The routines automatically opens a position upon a threshold crossing
    #
    def open_at_crossing
      count = 0
      WatchList.all.each do |wl|
        unless wl.open_crossed_at.nil?
          ss = Snapshot.find(:first, :conditions => { :ticker_id => wl.ticker_id, :bartime => wl.open_crossed_at })
          unless ss.nil?
            TdaPosition.create!(:ticker_id => wl.ticker_id, :watch_list_id => wl.id, :entry_price => ss.close,
                               :entry_date => ss.bartime.to_date, :opened_at => ss.bartime, :num_shares => 10000)
            count += 1
          end
        end
      end
      count
    end

    #
    # Loop through the tickers matching the scan testing if the price is closse enough (CUTOFF_PERCENT) to one of the three target rsi's.
    # If it passes the test, add it to the WatchList
    #
    def add_possible_entries()
      startt = Time.now
      logger.info("\n#{startt.to_s(:db)} -- Beginning search for new positions...")
      for ticker_id in candidate_ids
        begin
          ticker = Ticker.find ticker_id
          start_date = trading_date_from(Date.today, -6)
          end_date = trading_date_from(Date.today, -1)
          ts = Timeseries.new(ticker_id, start_date..end_date, 1.day)
          rsi = ts.rsi()
          last_close = ts.close.last
          last_volume = ts.volume.last

          thresholds = RSI_OPEN_THRESHOLDS
          thresholds.each do |threshold|
            next if rsi > threshold
            rsi_target_price = ts.invrsi(:rsi => threshold, :time_period => 14)
            # what happens we we have multiple watch list items per ticker?
            if  last_close < rsi_target_price && last_close >= (PRICE_CUTOFF_RATIO)*rsi_target_price
              begin
                #puts "#{ts.symbol}: #{rsi}\t#{last_close}"
                WatchList.create_or_update_listing(ticker_id, last_close, last_volume, rsi_target_price, rsi, threshold, Date.today, :logger => logger)
                break
              rescue Exception => e
                logger.info("Dup record #{e.to_s} for #{ts.symbol} at #{rsi_target_price} listed on #{Date.today.to_s(:db)}.")
              end
            elsif ( rsi >= RSI_CUTOFF and WatchList.find(:first, :conditions => { :ticker_id => ticker_id, :opened_on => nil} ))
              #logger.info("Deleting #{ts.symbol} RSI of #{rsi} above threhold of #{RSI_CUTOFF}")
              #WatchList.delete_all(:ticker_id => ticker_id, :opened_on => nil)
            elsif ( rsi >= threshold || last_close >= rsi_target_price )
              WatchList.update_listing(ticker_id, rsi_target_price, rsi, threshold, :logger => logger)
            end
          end
        rescue TimeseriesException => e
          logger.error(e.to_s)
        end
      end
      endt = Time.now
      logger.info("#{endt.to_s(:db)} -- Finished search for new positions. Elapsed time #{endt - startt}.")
      true
    end

    def update_exit_list()
      WatchList.find(:all, :conditions => 'opened_on IS NOT NULL').each do |opened_position|
        ticker_id = opened_position.ticker_id
        start_date = opened_position.opened_on
        end_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id })
        ts = Timeseries.new(ticker_id, start_date..end_date, 1.day)
        begin
          result_hash = ts.eval_crossing(closing_strategy_params)
          time = Time.zone.at(ts.bartime.last).to_datetime.midnight+1.day # daily bar crossings marked at midnight
          opened_position.update_closure!(result_hash, time, ts.close.last, 0)
          ts = Timeseries.new(ticker_id, start_date..end_date, 1.day) # eval crossing screws up the timeseries
          update_target_prices(opened_position, ts)
          update_closing_values(opened_position, ts)
        rescue TimeseriesException => e
          next
        end
      end
    end

    def update_target_prices(opos, ts)
      attrs = {}
      closing_strategy_params.each_pair do |meth, params|
        inverse_meth = "inv#{meth}".to_sym
        colname = "#{meth}_target_price".to_sym
        tprice = ts.send(inverse_meth, meth => params[:threshold])
        attrs[colname] = tprice
      end
      opos.update_attributes! attrs
    end

    def update_closing_values(opos, ts)
      attrs = {}
      rsi = ts.rsi()
      if opos.last_populate.nil?
        %w{ current last closing }.each { |prefix| attrs["#{prefix}_rsi".to_sym] = rsi }
        attrs[:last_populate] = Time.zone.now
      elsif opos.last_populate.to_date != Time.zone.now.to_date
        time = Time.zone.at(ts.bartime.last).to_datetime.midnight+1.day # daily bar crossings marked at midnight
        attrs[:last_rsi] = opos.closing_rsi
        %w{ current closing }.each { |prefix| attrs["#{prefix}_rsi".to_sym] = rsi }
        attrs[:last_populate] = Time.zone.now
        attrs[:closed_crossed_at] = (opos.indicators_crossed_at && (attrs[:last_rsi] >= rsi || trading_day_count(opos.opened_on, Date.today) >= 20) || nil) && time
      end
      opos.update_attributes!(attrs)
    end

    def purge_entry_list()
      WatchList.delete_all('opened_on IS NULL')
    end

    def populate_opening_list(update_daily=false)
      #
      # repopulate with possible entries that aren't stale
      #
      returning (Hash.new) do |hash|
        WatchList.find(:all, :conditions => 'opened_on IS NULL').each do |watched_position|
          ticker_id = Ticker.find watched_position.ticker_id
          start_date = watched_position.listed_on - 5.days
          end_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id })
          ts = Timeseries.new(ticker_id, start_date..end_date, 1.day)
          watched_position = watched_position.update_open_from_daily!(ts) if update_daily
          hash[ts] = [watched_position.target_rsi, watched_position.rsi_target_price]
        end
      end
    end

    def populate_closure_list
      returning [] do |vec|
        WatchList.find(:all, :conditions => 'opened_on IS NOT NULL').each do |opos|
          ticker_id = opos.ticker_id
          start_date = opos.opened_on
          end_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id })
          ts = Timeseries.new(ticker_id, start_date..end_date, 1.day)
          update_target_prices(opos, ts) if opos.rvi_target_price.nil?
        #  update_closing_values(opos, ts) unless open_position.close_crossed_at.nil? commented out to not color exit list red
         vec << ts
        end
      end
    end

    def generate_entry_csv()
      datestr = Date.today.to_formatted_s(:ymd)
      basename =  "Entry_List-#{datestr}.csv"
      filename = File.join(RAILS_ROOT, 'tmp', basename)
      FasterCSV.open(filename, 'w') do |csv|
        csv << [ 'Ticker', 'Percent', 'Price', 'Target Price', 'Volume', 'RSI', 'Threshold', 'Shares@Price' ]
        WatchList.find(:all, :conditions => 'opened_on is NULL', :order => 'price').each do |wl|
          row = []
          row << wl.ticker.symbol
          row << wl.target_percentage && format('%2.2f', wl.target_percentage) || '-'
          row << wl.price_f
          row << wl.rsi_target_price_f
          row << wl.volume
          row << wl.current_rsi_f
          row << wl.target_rsi_f
          row << wl.shares
          csv << row
        end
        csv.flush
      end
      Notifier.deliver_csv_notification(filename)
    end

    def start_watching()
      @qt = TdAmeritrade::QuoteServer.new
      @qt.attach_to_streamer()
      begin
        retrieve_snapshots()
      rescue Exception => e
        logger.error("#{Time.now}: retrieve_snapshot error: #{e.class}:#{e.to_s}")
        sleep(60) and retry
      end
      update_loop()
    end

    def update_loop
      loop do
        startt = Time.now
        ots_hash = populate_opening_list()
        cts_vec = populate_closure_list()
        update_openings(ots_hash)
        update_closures(cts_vec)
        endt = Time.now
        update_time = endt - startt
        sleep(60.0-update_time) if update_time < 60.0
        time = Time.now
        break if time.hour == 13 and time.min > 5
      end
    end

    def update_openings(ots_hash)
      ots_hash.each_pair do |ts, targets|
        threshold, rsi_target_price = targets
        WatchList.lookup_entry(ts.ticker_id, :open).each do |watch|
          qt.snapshot(ts.symbol)
          last_bar, num_samples = Snapshot.last_bar(ts.ticker_id, Date.today, true)
          next if num_samples.zero?
          if watch.last_snaptime.nil? or last_bar[:time] > watch.last_snaptime
            ts.update_last_bar(last_bar)
            current_rsi = ts.rsi()
            watch.update_open_from_snapshot!(last_bar, current_rsi, num_samples, Snapshot.last_seq(ts.symbol, Date.today))
          end
        end
      end
    end

    def update_closures(cts_vec)
      cts_vec.each do |ts|
        WatchList.lookup_entry(ts.ticker_id, :close).each do |watch|
          qt.snapshot(ts.symbol)
          last_bar, num_samples = Snapshot.last_bar(ts.ticker_id, Date.today, true)
          next if num_samples.zero?
          if watch.last_snaptime.nil? or last_bar[:time] > watch.last_snaptime
            ts.update_last_bar(last_bar)
            begin
              result_hash = ts.eval_crossing(closing_strategy_params)
              watch.update_closure!(result_hash, last_bar[:time], last_bar[:close], num_samples)
            rescue TimeseriesException => e
              next
            end
          end
        end
      end
    end
  end
end


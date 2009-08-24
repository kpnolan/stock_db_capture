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
        :macdfix => {:threshold => 0, :range => -1..1, :direction => :over, :result => :last_of_third},
        :rsi => {:threshold => 50, :range => 0..100, :direction => :under, :result => :last},
        :rvi => {:threshold => 50, :range => 0..100, :direction => :under, :result => :last}
      }
    end

    def create_candidate_list()
      @scan = Scan.find_by_name(WATCHLIST_NAME)

      start_date = Date.parse('1/1/2009')
      end_date = trading_days_from(Date.today, -1).last
      liquid = "min(volume) >= 100000 AND count(*) = #{total_bars(start_date, end_date, 1)}"
      scan.update_attributes!(:table_name => 'daily_bars',
                              :start_date => start_date, :end_date => end_date,
                              :join => nil,
                              :conditions => liquid)
      @candidate_ids = scan.population_ids()
    end

    def reset()
      create_candidate_list()
      add_possible_entries()
    end

    def clear_watch_list
      # TODO delete vestigial watch list entries that have been closed or terminated
    end

    def length
      ots_hash.length
    end

    def test_snapshot_server
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
    # The routines automatically opens a position upon a theshold crossing
    #
    def open_at_crossing
      count = 0
      WatchList.all.each do |wl|
        unless wl.open_crossed_at.nil?
          ss = Snapshot.find(:first, :conditions => { :ticker_id => wl.ticker_id, :snaptime => wl.open_crossed_at })
          unless ss.nil?
            TdaPosition.create!(:ticker_id => wl.ticker_id, :watch_list_id => wl.id, :entry_price => ss.close,
                                :entry_date => ss.snaptime.to_date, :opened_at => ss.snaptime, :num_shares => 10000)
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
        #begin
        ticker = Ticker.find ticker_id
        start_date = trading_days_from(Date.today, -1).last
        end_date = trading_days_from(Date.today, -1).last
        ts = Timeseries.new(ticker, start_date..end_date, 1.day)
        rsi = ts.rsi(:time_period => 14, :result => :last)
        last_close = ts.close.last

        thresholds = RSI_OPEN_THRESHOLDS
        thresholds.each do |threshold|
          target_price = ts.invrsi(:rsi => threshold, :time_period => 14)
          # what happens we we have multiple watch list items per ticker?
          if  rsi < threshold or last_close < target_price && last_close >= (PRICE_CUTOFF_RATIO)*target_price
            begin
              WatchList.create_or_update_listing(ticker_id, target_price, rsi, threshold, Date.today, :logger => logger)
              break
            rescue Exception => e
              logger.info("Dup record #{e.to_s} for #{ts.symbol} at #{target_price} listed on #{Date.today.to_s(:db)}.")
            end
          elsif ( rsi >= RSI_CUTOFF and WatchList.find(:first, :conditions => { :ticker_id => ticker_id, :opened_on => nil} ))
            logger.info("Deleting #{ts.symbol} RSI of #{rsi} above threhold of #{RSI_CUTOFF}")
            WatchList.delete_all(:ticker_id => ticker_id, :opened_on => nil)
          end
        end
        #rescue Exception => e
        #  logger.error(e.to_s)
        #  next
        #end
      end
      endt = Time.now
      logger.info("#{endt.to_s(:db)} -- Finished search for new positions. Elapsed time #{endt - startt}.")
      true
    end

    def populate_opening_list
      #
      # repopulate with possible entry that aren't stale
      #
      returning (Hash.new) do |hash|
        WatchList.find(:all, :conditions => 'opened_on IS NULL').each do |watched_position|
          ticker_id = Ticker.find watched_position.ticker_id
          start_date = watched_position.listed_on
          end_date = DailyBar.maximum(:date, :conditions => { :ticker_id => ticker_id })
          ts = Timeseries.new(ticker_id, start_date..end_date, 1.day)
          hash[ts] = [watched_position.target_rsi, watched_position.target_price]
        end
      end
    end

    def populate_closure_list
      returning [] do |vec|
        WatchList.find(:all, :conditions => 'opened_on IS NOT NULL').each do |opened_position|
          ticker_id = opened_position.ticker_id
          start_date = opened_position.tda_position.entry_date
          end_date = DailyBar.maximum(:date, :conditions => { :ticker_id => ticker_id })
          vec << Timeseries.new(ticker_id, start_date..end_date, 1.day)
        end
      end
    end

    def start_watching()
      @qt = TdAmeritrade::QuoteServer.new
      @qt.attach_to_streamer()
      begin
        test_snapshot_server()
      rescue Exception
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
        threshold, target_price = targets
        returning WatchList.lookup_entry(ts.ticker_id) do |watch|
          begin
            unless qt.snapshot(ts.symbol).zero? and not watch.last_snaptime.nil?
              last_bar, num_samples = Snapshot.last_bar(ts.ticker_id, Date.today, true)
              if watch.last_snaptime.nil? or last_bar[:time] > watch.last_snaptime
                ts.update_last_bar(last_bar)
                current_rsi = ts.rsi(:time_period => 14, :result => :last)
                watch.update_open_from_snapshot!(last_bar, current_rsi, num_samples, Snapshot.last_seq(ts.symbol, Date.today))
              end
            end
          rescue Exception => e
            logger.error("Exception -- #{ts.symbol} on  msg: #{e.to_s}")
          end
        end
      end
    end

    def update_closures(cts_vec)
      cts_vec.each do |ts|
        returning WatchList.lookup_entry(ts.ticker_id) do |watch|
          begin
            unless qt.snapshot(ts.symbol).zero? and not watch.last_snaptime.nil?
              last_bar, num_samples = Snapshot.last_bar(ts.ticker_id, Date.today, true)
              if watch.last_snaptime.nil? or last_bar[:time] > watch.last_snaptime
                ts.update_last_bar(last_bar)
                result_hash = ts.eval_crossing(closing_strategy_params)
                watch.update_closure!(result_hash, last_bar,  num_samples)
              end
            end
          rescue Exception => e
            logger.error("Exception -- #{ts.symbol} on msg: #{e.to_s}")
          end
        end
      end
    end
  end
end


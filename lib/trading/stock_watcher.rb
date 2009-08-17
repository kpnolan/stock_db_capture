module Trading

  class StockWatcher

    include TradingCalendar

    WATCHLIST_NAME = 'Watchlist_2009'
    PREWATCH_NAME = 'Prewatch_2009'
    RSI_CUTOFF_PERCENT = 20.0/25.0 - 1.0
    PRICE_CUTOFF_PERCENT = 85.0
    RSI_OPEN_THRESHOLDS = [20.0, 25.0, 30.0]

    attr_reader :candidate_ids, :scan, :ots_hash, :cts_vec, :qt, :logger

    def initialize(logger, options={})
      @logger = logger
      @ots_hash = { }                   # hash of timeeries one entry each for a posible watched for openning
      @cts_vec = []                     # vector o timeseries one each for possible closures
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
      @ots_hash = Hash.new
      @cts_vec = Array.new
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
          openning_thresholds = RSI_OPEN_THRESHOLDS.map do |threshold|
            target_price = ts.invrsi(:rsi => threshold, :time_period => 14)
            if ( rsi < threshold && rsi >= (RSI_CUTOFF_PERCENT/100.0) * threshold or
                 last_close < target_price && last_close >= (PRICE_CUTOFF_PERCENT/100.0) * target_price)
              begin
                WatchList.create_openning(ticker_id, target_price, rsi, threshold, Date.today)
              rescue Exception => e
                logger.info("Dup record #{e.to_s} for #{ts.symbol} at #{target_price}, ignored.")
                WatchList.dispose(ticker_id, rsi, threshold) and retry
              end
              logger.info("Added (#{ts.symbol}) tp: #{target_price} : #{last_close}\t#{threshold} -- Rsi: #{rsi}")
              break
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

    def repopulate
      #
      # repopulate with possible entry that aren't stale
      #
      @ots_hash = Hash.new()
      WatchList.find(:all, :conditions => { :stale_date => nil }).each do |watched_position|
        ticker_id = Ticker.find watched_position.ticker_id
        start_date = watched_position.entered_on
        end_date = DailyBar.maximum(:date, :conditions => { :ticker_id => ticker_id })
        ts = Timeseries.new(ticker_id, start_date..end_date, 1.day)
        self.ots_hash[ts] = [watched_position.target_ival, watched_position.target_price]
      end
    end

    def add_open_positions()
      open_posiions = TdaPositions.find(:all, :conditions => { :com => false })
      for position in open_positions
        ticker_id = position.ticker_id
        WatchList.create_closure(position, nil, 60.0)
        ts = Timeseries.new(ticker_id, scan.start_date..scan.end_date)
        self.cts_vec << ts
      end
      cts_vec.length
    end

    def start_watching()
      repopulate()
      @qt = TdAmeritrade::QuoteServer.new
      @qt.attach_to_streamer()
      test_snapshot_server()
      begin
        test_snapshot_server()
      rescue
        sleep(60) and retry
      end
      update_loop()
    end

    def update_loop
      loop do
        update_time = update_openings()
        sleep(60.0-update_time) if update_time < 60.0
        time = Time.now
        break if time.hour == 13 and time.min > 5
      end
    end

    def update_openings()
      repopulate if ots_hash.empty?
      startt = Time.now
      ots_hash.each_pair do |ts, targets|
        threshold, target_price = targets
        new_sample_count = qt.snapshot(ts.symbol)
        if new_sample_count > 0
          last_bar = Snapshot.last_bar(ts.ticker_id)
          begin
            ts.update_last_bar(last_bar)
            current_rsi = ts.rsi(:time_period => 14, :result => :last)
            pred_price, sd, num_samples = Snapshot.predict(ts.symbol)
            WatchList.lookup_entry(ts.ticker_id).each do |watch|
              watch.update_from_snapshot!(last_bar, current_rsi, num_samples, pred_price, sd, Snapshot.last_seq(ts.symbol, Date.today))
            end
          rescue Exception => e
            logger.error("Exception -- Snaphot for #{ts.symbol} on #{last_bar[:time].to_s(:db)} yields: #{e.to_s}")
          end
        end
      end
      endt = Time.now
      deltat = endt - startt
    end
  end

  def init_closures

  end

  def update_closures()
    cst_vec.each do |ts|
      #TODO fill these in
    end
  end
end

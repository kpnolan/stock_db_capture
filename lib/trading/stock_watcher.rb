module Trading

  class StockWatcher

    include TradingCalendar

    WATCHLIST_NAME = 'Watchlist_2009'
    PREWATCH_NAME = 'Prewatch_2009'
    RSI_CUTOFF_PERCENT = 90.0
    PRICE_CUTOFF_PERCENT = 85.0

    attr_reader :candidate_ids, :scan, :ots_hash, :cts_vec, :qt

    def initialize(options={})
      @ots_hash = { }                   # hash of timeeries one entry each for a posible watched for openning
      @cts_vec = []                     # vector o timeseries one each for possible closures
      @qt = TdAmeritrade::QuoteServer.new
      @qt.attach_to_streamer()
      test_snapshot_server()
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

    def logger
      log_name = "stock_watch_#{Date.today.to_s(:db)}.log"
      @logger ||= ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', log_name))
    end

    def reset()
      clear_watch_list()
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
        qt.snapshot('IBM')
        @snapshots_active = true
      rescue SnapshotProtocolError
        @snapshots_active = false
      rescue Exception => e
        logger.error("#{Time.now.to_s(:db)}: #{e.to_s}")
        @snapshot_active = true
      end
    end

    #
    # Loop through the tickers matching the scan testing if the price is closse enough (CUTOFF_PERCENT) to one of the three target rsi's.
    # If it passes the test, add it to the WatchList
    #
    def add_possible_entries()
      for ticker_id in candidate_ids
        #begin
          ticker = Ticker.find ticker_id
          start_date = trading_days_from(Date.today, -1).last
          end_date = trading_days_from(Date.today, -1).last
          ts = Timeseries.new(ticker, start_date..end_date, 1.day)
          rsi = ts.rsi(:time_period => 14, :result => :first)[-1]
          puts format("%3.3f", rsi)
          last_close = ts.close.last
          openning_thresholds = [20.0, 25.0, 30.0].map do |threshold|
            target_price = ts.invrsi(:rsi => threshold, :time_period => 14)
            if ( rsi < threshold && rsi >= (RSI_CUTOFF_PERCENT/100.0) * threshold or
                 last_close < target_price && last_close >= (PRICE_CUTOFF_PERCENT/100.0) * target_price)
              WatchList.create_openning(ticker_id, target_price, rsi, threshold, start_date)
              puts "(#{ts.symbol}) tp: #{target_price} : #{last_close}\t#{threshold} -- Rsi: #{rsi}" #if ots_hash[ts].nil?
              self.ots_hash[ts] = [threshold, target_price]
              break
            end
          end
        #rescue Exception => e
        #  logger.error(e.to_s)
        #  next
        #end
      end
      true
    end

    def repopulate
      #
      # repopulate with possible opennings
      #
      @ots_hash = Hash.new()
      WatchList.find(:all, :conditions => { :tda_position_id => nil }).each do |watched_position|
        ticker_id = Ticker.find watched_position.ticker_id
        start_date = watched_position.entered_on
        end_date = watched_position.last_snaptime.nil? ? start_date : watched_position.last_snaptime.to_date
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

    def update_loop
      loop do
        update_time = update_openings()
        update_time > 0.0 ? sleep(60.0-update_time) : sleep(60)
      end
    end

    def update_openings()
      startt = Time.now
      snap_count = 0
      watch_count = 0
      ots_hash.each_pair do |ts, targets|
        threshold, target_price = targets
        new_sample_count = qt.snapshot(ts.symbol)
        if new_sample_count > 0
          last_bar = Snapshot.last_bar(ts.ticker_id)
          snap_count += 1
          begin
            ts.update_last_bar(last_bar)
            current_rsi = ts.rsi(:time_period => 14, :result => :last)
            pred_price, sd, num_samples = Snapshot.predict(ts.symbol)
            watch = WatchList.lookup_entry(ts.ticker_id)
            watch.update_from_snapshot!(last_bar, current_rsi, num_samples, pred_price, sd, Snapshot.last_seq(ts.symbol, Date.today))
            watch_count += 1
          rescue Exception => e
            puts e.to_s
            logger.error("Snaphot for #{ts.symbol} on #{last_bar[:time].to_s(:db)} yields: #{e.to_s}")
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

    end
  end
end

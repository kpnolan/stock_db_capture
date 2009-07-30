module Trading

  class StockWatcher

    include TradingCalendar

    WATCHLIST_NAME = 'Watchlist_2009'
    PREWATCH_NAME = 'Prewatch_2009'
    CUTOFF_PERCENT = 90.0

    attr_reader :candidate_ids, :scan, :ots_hash, :cts_vec, :qt, :logger

    def initialize(options={})
      log_name = "stock_watch_#{Date.today.to_s(:db)}.log"
      @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', log_name))
      @ots_hash = { }
      @cts_vec = []
      clear_watch_list()
      create_candidate_list()
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


    def reset()
      clear_watch_list()
      add_possible_entries()
    end

    def clear_watch_list
      WatchList.delete_all
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
        begin
          ticker = Ticker.find ticker_id
          start_date = trading_days_from(Date.today, -1).last
          end_date = trading_days_from(Date.today, -1).last
          ts = Timeseries.new(ticker, start_date..end_date, 1.day,
                              :pre_buffer => :rsi, :post_buffer => 0, :time_period => 14, :populate => true)
          rsi = ts.rsi(:time_period => 14, :result => :raw).first.to_a.last
          last_close = ts.close.last
          openning_thresholds = [20.0, 25.0, 30.0].map do |threshold|
            if ( rsi < threshold && rsi >= (CUTOFF_PERCENT/100.0) * threshold )
              target_price = ts.invrsi(:rsi => threshold, :time_period => 14)
              WatchList.create_openning(ticker_id, target_price, rsi, threshold)
              puts "(#{ts.symbol}) Rsi: #{rsi}" if ots_hash[ts].nil?
              self.ots_hash[ts] ||= []
              self.ots_hash[ts] << [threshold, target_price]
            end
          end
        rescue Exception => e
          logger.error(e.to_s)
          next
        end
      end
      true
    end

    def add_open_positions()
      open_posiions = TdaPositions.find(:all, :conditions => { :com => false })
      for position in open_positions
        ticker_id = position.ticker_id
        WatchList.create_closure(position, nil, 60.0)
        ts = Timeseries.new(ticker_id, scan.start_date..scan.end_date, 1.day,
                            :pre_buffer => :ema, :post_buffer => 0, :time_period => 14)
        self.cts_vec << ts
      end
      cts_vec.length
    end

    def update_status()
      startt = Time.now
      snap_count = 0
      watch_count = 0
      ots_hash.each_pair do |ts, tuples|
        begin
          new_sample_count = qt.snapshot(ts.symbol)
          if new_sample_count > 0
            last_snap = Snapshot.last_bar(ts.ticker_id)
            snap_count += 1
            begin
              ts.update_last_bar(last_snap)
              rsi_vec = ts.rsi(:time_period => 14, :result => :raw).first
              puts "(#{ts.symbol}) Rsi: #{rsi_vec.to_a.join(', ')}"
              current_rsi = rsi_vec.last
              pred_price, sd, num_samples = Snapshot.predict(ts.symbol)
              for tuple in tuples
                threshold, target_price = tuple
                watch = WatchList.lookup_entry(ts.ticker_id, threshold)
                watch.update_from_snapshot!(last_snap[:close], current_rsi, num_samples, pred_price, 0, sd, last_snap[:time])
                watch_count += 1
              end
            rescue Exception => e
              puts e.to_s
              logger.error("Snaphot for #{ts.symbol} on #{last_snap[:time].to_s(:db)} yields: #{e.to_s}")
            end
          end
        rescue Exception => e
          puts e.to_s
          logger.error(e.to_s)
        end
      end
      endt = Time.now
      deltat = endt - startt
      watch_count = WatchList.count
      logger.info("#{startt.to_s(:db)} update status took #{deltat/60.0} minutes for #{snap_count} snapshots and #{watch_count} watch list entries")
      true
    end
  end
end

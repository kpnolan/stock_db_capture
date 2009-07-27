class StockWatcher

  include TradingCalendar

  WATCHLIST_NAME = 'Watchlist_2009'
  PREWATCH_NAME = 'Prewatch_2009'
  CUTOFF_PERCENT = 90.0

  attr_reader :candidate_ids, :scan, :ots_vec, :cts_vec, :qt

  def initialize(options={})
    clear_watch_list()
    create_candidate_list()
    add_possible_entries()
    @ots_vec = []
    @cts_vec = []
    @qt = TdAmeritrade::QuoteServer.new
    @qt.attach_to_streammer()
    test_snapshot_server()
  end

  def creat_candiate_list()
    @scan = Scan.find_by_name(WATCHLIST_NAME)

    start_date = Date.parse('1/1/2009')
    end_date = trading_days_from(Date.today, -1).last
    liquid = "min(volume) >= 100000 and count(*) = #{total_bars(start_date, end_date, 1)}"
    scan.update_attribute!(:start_date => start_date, :end_date => end_date, :conditions => liquid)
    @candidate_ids = scan.ticker_ids
  end

  def clear_watch_list
    WatchList.delete_all
  end

  def test_snapshot_server
    begin
      $qt.snapshot('IBM')
      @snapshots_active = true
    rescue SnapshotProtocolError
      @snapshots_active = false
    end
  end

  #
  # Loop through the tickers matching the scan testing if the price is closse enough (CUTOFF_PERCENT) to one of the three target rsi's.
  # If it passes the test, add it to the WatchList
  #
  def add_possible_entries()
    for id in candidate_ids
      ticker = Ticker.find id
      ts = Timeseries.new(ticker, scan.start_date..scan.end_date, 1.day,
                          :pre_buffer => :ema, :post_buffer => 0, :time_period => 14)
      close_thresholds = [20, 25, 30].map do |threshold|
        [ threshold, ts.invrsi(threshold, :rsi => threshold.to_f, :time_period => 14) ]
      end
      last_close = ts.close.last
       close_threshold.each do |pair|
        target_ival, target_price = pair
        if ( last_close < ct && last_close >= (CUTOFF_THRESHOLD/100.0) * ct )
          WatchList.create_openning(id, target_price, target_ival)
          @ots_vec = ts
        end
      end
    end
  end

  def add_open_positions()
    open_posiions = TdaPositions.find(:all, :conditions => { :com => false })
    for position in open_positions
      ticker_id = position.ticker_id
      WatchList.create_closure(position, nil, 60.0)
      ts = Timeseries.new(ticker_id, scan.start_date..scan.end_date, 1.day,
                          :pre_buffer => :ema, :post_buffer => 0, :time_period => 14)
      @cts_vec = ts
    end
  end

  def update_status()
    startt = Time.now
    watch_list = WatchList.all
    begin
      for entry in watch_list
        samples = qt.snapshot(entry.ticker.symbol)
        if samples > 0
          curr_price = Snapshot.last_close()
          price, sd, num_samples = Snapshot.predict(position.ticker)
          # TODO fill in rest of fields
        end
      end
    end
  end
end

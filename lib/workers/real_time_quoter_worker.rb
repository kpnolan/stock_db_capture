# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.
class RealTimeQuoterWorker < BackgrounDRb::Rails

  repeat_every 5.minutes
  first_run Time.parse('12/19/2008 5:00')

  def do_work(args)
    @cache = $cache.clone

    symbols = args[:symbols]
    csize = args[:chunk_size]

    len = symbols.length
    ldr = TradingDBLoader.new('r', :logger => @logger, :memcache => @cache)
    @cache.set('QuoteCount:RealTimeQuote', len, nil, false)
    @cache.set('QuoteCounter:RealTimeQuote', 0, nil, false)
    @cache.set('RealTimeQuote:Status', 'processing', nil, false)

    while true
      idx = next_chunk(csize)
      ids_remaining = (len - idx) - 1
      working_size = ids_remaining > csize ? csize : ids_remaining
      if working_size > 0
        working_ids = symbols.slice(idx, working_size)
        ldr.load_quotes(working_ids)
      else
        reset(idx)
        break
      end
    end
  end

  def next_chunk(size)
    index = nil
    begin
      @cache.cas('Ticker:RealTimeQuoteWorker:index', nil, false) { |value| (index = value.to_i) + size }
      index
    rescue Memcached::ConnectionDataExists
      retry
    end
  end

  def reset(last_index)
    begin
      @cache.cas('Ticker:RealTimeQuoteWorker:index', nil, false) { |value| 0 }
      @cache.increment('Ticker:RealTimeQuoteWorker:iteration_count')
    rescue Memcached::NotStored
      @cache.get('Ticker:RealTimeQuoteWorker:index').to_i >= last_index and retry
    end
  end
end

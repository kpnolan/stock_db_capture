require 'rubygems'
require 'memcached'

namespace :active_trader do

  desc "Setup the environment for live quote capture"
  task :setup => :environment do
    @symbols = Ticker.active_symbols
    @len = @symbols.length

    $cache.set('LiveQuotes:index', 0, nil, false)
    $cache.set('LiveQuotes:iteration_count', 0, nil, false)
    $cache.set('LiveQuotes:chunk_size', 500, nil, false)
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'capture_live_quotes.log'))
    @logger.add(5, "\n")
    @ldr = TradingDBLoader.new('s', :logger => @logger, :memcache => $cache)
  end

  desc "Start the process which retrieves live quotes from yahoo"
  task :capture_live_quotes => :setup do
    begin
      while true
        csize = $cache.get('LiveQuotes:chunk_size', false).to_i
        idx = next_chunk(csize)
        ids_remaining = (@len - idx) - 1
        working_size = ids_remaining > csize ? csize : ids_remaining
        if working_size > 0
          working_ids = @symbols.slice(idx, working_size)
          @ldr.load_quotes(working_ids)
        else
          reset(idx)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      puts e.inspect
      if (t = Time.now) && t.hour >= 13
        @logger.info("Shutting Down Live Capture at #{Time.now}")
        @logger.close
      else
        @logger.error(e.to_s)
      end
    end
  end

  desc "Display progress counters for live quote capture"
  task :stats do
    cache = Memcached.new(["amd64:11211:2"], :support_cas => true, :show_backtraces => true)
    index, iter = cache.get('LiveQuotes:index', false), cache.get('LiveQuotes:iteration_count', false)
    puts "Iteration: #{index} Index: #{iter}"
  end

  def next_chunk(size)
    index = nil
    begin
      $cache.cas('LiveQuotes:index', nil, false) { |value| (index = value.to_i) + size }
      index
    rescue Memcached::ConnectionDataExists
      retry
    end
  end

  def reset(last_index)
    begin
      $cache.cas('LiveQuotes:index', nil, false) { |value| 0 }
      $cache.increment('LiveQuotes:iteration_count')
    rescue Memcached::NotStored
      $cache.get('LiveQuotes:index').to_i >= last_index and retry
    end
  end
end

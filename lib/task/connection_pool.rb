#require 'rubygems'                          #1.8.7
#require 'ruby-debug'

require 'thread'
require 'forwardable'
require 'beanstalk-client'

class Hash
  def splat(*syms)
    syms.map { |k| fetch(k) }
  end
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end

  def reverse_merge!(other_hash)
    merge!( other_hash ){|k,o,n| o }
  end
end

module Task
  #
  class Channel
    extend Forwardable

    def_delegators :@con, :stats, :peek_ready, :peek_delayed, :peek_buried, :peek_job, :delete
    def_delegators :@con, :connect, :close, :list_tubes, :ignore, :job_stats, :list_tubes_used, :list_tubes_watched


    attr_reader :con

    def initialize(manager, con)
      @mgr = manager
      @con = con
    end

    def put(body, opts={})
      opts.reverse_merge! :pri => 65536, :delay => 0, :ttr => 120
      con.put(body, *opts.splat(:pri, :delay, :ttr))
    end

    def release(id, opts={})
      opts.reverse_merge! :pri => 65536, :delay => 0
      con.release(id, *opts.splat(:pri, :delay))
    end

    def yput(obj, opts={})
      opts.reverse_merge! :pri => 65536, :delay => 0, :ttr => 120
      con.yput(body, *opts.splat(:pri, :delay, :ttr))
    end

    def stats_tube(tube=@mgr.tube)
      con.stats_tube(tube)
    end

    def retire()
      @mgr.give_back(self)
    end

    def to_s
      "channel for #{@mgr.dir} #{@mgr.tube}"
    end
  end
  #
  class OutputChannel < Channel
    def initialize(manager, con)
      super(manager, con)
    end
  end
  #
  class InputChannel < Channel

    def initialize(manager, con)
      super(manager, con)
    end

    def reserve(timeout=0)
      begin
        job = con.reserve(timeout)
      rescue Beanstalk::TimedOut, Beanstalk::WaitingForJobError => e
        $stderr.puts "#{@mgr.tube} reserve: #{e}"
      end
    end

    def ingnore()
      super(tube) if tube
    end

    def close()
      ignore()
      super()
    end

    def sync_each()
      while true
        job = reserve(0)
        return job if job.nil?
        yield job
        job.delete
      end
    end
  end
  #
  class ConnectionMgr

    attr_reader :tube, :dir, :free_list, :in_use, :size
    attr_accessor :round

    def initialize(tube, direction, size)
      @tube = tube
      @dir = direction
      @free_list = populate(size)
      @in_use = []
      @round = 0
    end

    def round_robin()
      channel = free_list[(@round+=1)%size]
    end

    def take()
      channel = free_list.pop
      in_use.push(channel)
      raise RuntimeError, "free list for #{dir} tube #{tube} is STILL empty" if channel.nil?
      channel
    end

    def take1(&block)
      channel = take()
      begin
        result = yield channel
      ensure
        give_back(channel)
      end
      result
    end

    def give_back(channel)
      free_list.push(channel)
      if in_use.last == channel
        in_use.pop
      else
        in_use.delete(channel)
      end
    end

    private

    def alloc_connection(tube, direction)
      case direction
      when :input then
        channel = InputChannel.new(self, Beanstalk::Connection.new('127.0.0.1:11300', tube))
      when :output then
        channel = OutputChannel.new(self, Beanstalk::Connection.new('127.0.0.1:11300', tube))
      end
    end

    def populate(size)
      @size = size
      @free_list = Array.new(size) { alloc_connection(tube, dir) }
    end

    def close()
      (free_list+in_use).each { |channel| channel.close }
    end
  end
  #
  class ConnectionPool
    #
    # A Channel know from which Connection Managers (and therefore free list) it came from making
    # retirement back to the correct free list trivial
    #
    # Allocate an input and output connection for each consumer
    #
    def initialize(names, size)
      @input_map = { }
      @output_map = { }

      names.each do |name|
        alloc_connections(name, size)
      end
    end

    def take(name)
      @input_map[name].take
    end

    def [](name)
      ->(contents) { publish(name, contents) }                #1.9.2
#      lambda(contents) { publish(name, contents) }                #1.8.7
    end

    def alloc_connections(name, size)
      @input_map[name] ||= ConnectionMgr.new(name, :input, size)
      @output_map[name] ||= ConnectionMgr.new(name, :output, size)
    end

    def publish(name, contents)
      channel = @output_map[name].round_robin()
      jobid = channel.put(contents, :ttr => 2400)
    end

    def shutdown
      @input_map.values.each { |mgr| mgr.close }
      @output_map.values.each { |mgr| mgr.close }
    end
  end
end

#
# Unit and Capicity Test -- generates a flood of logger meesage
# just to see what the bandwidth and latency is.
#
if __FILE__ == $0

  names = [:scan_gen, :timeseries_args, :rsi_trigger_14, :rsi_rvi_50]
  cpool = Task::ConnectionPool.new(names, 2)

  startt = Time.now
  count = 100_000
  t1 = Thread.new(cpool) { |cpool|
    for count in 1..count
      jobid = cpool.publish(names.first, Marshal.dump(count+=1))
    end
  }

  t2 = Thread.new(cpool) { |cpool|
    channel = cpool.take(names.first)
    begin
      channel.sync_each do |job|
        break if Marshal.load(job.body) == count
        job.delete()
      end
    rescue Exception => e
      $stderr.puts e
      $stderr.puts "count: #{count}"
    end
  }

  t1.join
  t2.join

  dt = Time.now-startt
  msglen = 4
  puts "#{count} messages of length #{msglen} in #{dt} seconds #{count/dt} messages/sec"
end

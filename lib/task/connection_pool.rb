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

    attr_reader :mgr, :con, :copts

    def initialize(manager, con, cattrs)
      @mgr = manager
      @con = con
      @copts = cattrs
    end

    def put(body, opts=copts)
      opts.reverse_merge! :pri => 65536, :delay => 0, :ttr => 160
      con.put(body, *opts.splat(:pri, :delay, :ttr))
    end

    def release(id, opts=copts)
      opts.reverse_merge! :pri => 65536, :delay => 0
      con.release(id, *opts.splat(:pri, :delay))
    end

    def yput(obj, opts=copts)
      opts.reverse_merge! :pri => 65536, :delay => 0, :ttr => 120
      con.yput(body, *opts.splat(:pri, :delay, :ttr))
    end

    def stats_tube(tube=@mgr.tube)
      str = con.stats_tube(tube)
    end

    def retire()
      @mgr.give_back(self)
    end

    def to_s
      "channel for #{@mgr.dir} #{@mgr.tube} settings: #{copts}"
    end
  end
  #
  class OutputChannel < Channel
    def initialize(manager, con, csettings)
      super(manager, con, csettings)
    end
  end
  #
  class InputChannel < Channel

    def initialize(manager, con, csettings)
     super(manager, con, csettings)
    end

    def reserve(timeout=copts[:timeout])
      timeout ||= 60
      retries = 0
      $stderr.puts "begin reserve with time out #{timeout} on tube: #{mgr.tube}" #if [:task3,:task4,:task5].include? mgr.tube
      begin
        job = con.reserve(timeout)
        $stderr.puts "reserveed job #{job.id} time out #{timeout} on tube: #{mgr.tube}" #if [:task3,:task4,:task5].include? mgr.tube
        job
      rescue Beanstalk::TimedOut, Beanstalk::WaitingForJobError => e
        $stderr.puts "timed out on tube: #{mgr.tube}"
        retries +=1
        copts[:retries] && retries <= copts[:retries] && (h = stats_tube(@mgr.tube)) && h['current-jobs-ready'] > 0 &&
          peak_ready() and retry
        raise e unless copts[:no_raise]
        nil
      end
    end

    def ignore()
      super(mgr.tube) if mgr.tube
    end

    def close()
      ignore()
      super()
    end

    def sync_each()
      while true
        job = reserve()
        return job if job.nil?
        yield job
        job.delete
      end
    end
  end
  #
  class ConnectionMgr

    attr_reader :tube, :dir, :free_list, :in_use, :size, :cattrs
    attr_accessor :round

    def initialize(tube, direction, size, csettings)
      @tube = tube
      @dir = direction
      @cattrs = csettings
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

    def give_back(channel)
      free_list.push(channel)
      if in_use.last == channel
        in_use.pop
      else
        in_use.delete(channel)
      end
    end

    def close()
      (free_list+in_use).each { |channel| channel.close }
    end

    private

    def alloc_connection(tube, direction)
      case direction
      when :input then
        channel = InputChannel.new(self, Beanstalk::Connection.new('127.0.0.1:11300', tube), cattrs)
      when :output then
        channel = OutputChannel.new(self, Beanstalk::Connection.new('127.0.0.1:11300', tube), cattrs)
      end
    end

    def populate(size)
      @size = size
      @free_list = Array.new(size) { alloc_connection(tube, dir) }
    end
  end
  #
  class ConnectionPool
    attr_reader :csettings
    #
    # A Channel know from which Connection Managers (and therefore free list) it came from making
    # retirement back to the correct free list trivial
    #
    # Allocate an input and output connection for each consumer
    #
    def initialize(names, size, csettings={})
      @input_map = { }
      @output_map = { }
      @csettings = csettings

      names.each do |name|
        alloc_connections(name, size, csettings[name])
      end
    end

    def take(name, dir=:input)
      case dir
        when :input then @input_map[name].take
        when :output then @output_map[name].take
      else
        raise ArgumentError, 'dir must be :input or :output'
      end
    end

    def ytake(name, dir, &block)
      channel = take(name, dir)
      begin
        result = yield channel
      ensure
        channel.retire
      end
      result
    end

    def [](name)
      ->(contents) { publish(name, contents) }                #1.9.2
    end

    def alloc_connections(name, size, cattrs)
      @input_map[name] ||= ConnectionMgr.new(name, :input, size, cattrs)
      @output_map[name] ||= ConnectionMgr.new(name, :output, size, cattrs)
    end

    def publish(name, contents)
      channel = @output_map[name].round_robin()
      jobid = channel.put(contents)
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

  names = [:scan_gen, :timeseries_args, :rsi_trigger_14, :rsi_rvi_50, :lagged_rsi_difference]

  ct = []
  channel = []
  csettings = {
    scan_gen:              { pri: 1, timeout: 3,  retries: 0,  ttr: 5,  no_raise: true },
    timeseries_args:       { pri: 2, timeout: 3,  retries: 0,  ttr: 5,  no_raise: true },
    rsi_trigger_14:        { pri: 3, timeout: 3,  retries: 0,  ttr: 5,  no_raise: true },
    rsi_rvi_50:            { pri: 4, timeout: 3,  retries: 0,  ttr: 5,  no_raise: true },
    lagged_rsi_difference: { pri: 5, timeout: 3,  retries: 0,  ttr: 5,  no_raise: true },
  }
  cpool = Task::ConnectionPool.new(names, 1, csettings)
  cpool

  nlen = names.length
  startt = Time.now

  count = 100_000
  acount = Array.new(nlen, 0)
  pt = Thread.new(cpool) { |cpool|
    count.times do |i|
      nlen.times { |j| cpool.publish(names[j], Marshal.dump(i)) }
    end
  }
  #
  # create 5 threads to model what the backtester actually does to see if it 'loses' records
  #
  nlen.times do |i|
    ct[i] = Thread.new(cpool, i) { |cpool, i|
      channel[i] = cpool.take(names[i], :input)
      begin
        channel[i].sync_each do |job|
          acount[i] += 1
        end
      rescue Exception => e
        $stderr.puts e
        $stderr.puts "count: #{acount}"
      end
    }
  end

  pt.join
  ct.each { |t| t.join }
  actual_count = acount.inject(&:+)
  dt = Time.now-startt
  msglen = 4
  puts "#{actual_count} messages of length #{msglen} in #{dt} seconds #{actual_count/dt} messages/sec"
end

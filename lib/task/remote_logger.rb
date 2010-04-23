require 'monitor'
require 'drb/drb'

class RemoteLogger
  attr_reader :logger, :proc_id

  def initialize(proc_id=0, uri='druby://localhost:9999')
    @logger = DRbObject.new_with_uri(uri)
    @proc_id = proc_id
    @logger.extend(MonitorMixin)
   end

  private

  def log(msg, task_name, method)
    logger.synchronize { logger.send(method, "#{method.to_s.upcase}\t[#{proc_id}:#{task_name}] #{msg}") }
  end

  public

  def debug(msg, task_name='?')
    log(msg, task_name, :debug)
  end

  def info(msg, task_name='?')
    log(msg, task_name, :info)
  end

  def error(msg, task_name='?')
    log(msg, task_name, :error)
  end

  def fatal(msg, task_name='?')
    log(msg, task_name, :fatal)
  end
end

#
# Unit and Capicity Test -- generates a flood of logger meesage
# just to see what the bandwidth and latency is.
#
if __FILE__ == $0
  threads = []
  threads.extend(MonitorMixin)

  tl = TaskLogger.new(ARGV.first.to_i)
  10.times do |i|
    Thread.new(tl, i) do |tl, i|
      threads.synchronize { threads.push(Thread.current) }
      1000.times do
        case rand(3)
        when 0 then tl.debug('this is a debug msg', i.to_s)
        when 1 then tl.info('this is a info msg', i.to_s)
        when 2 then tl.error('this is a error msg', i.to_s)
        when 3 then tl.fatal('this is a fatal msg', i.to_s)
        end
      end
    end
  end
  threads.each { |thread| thread.join }
end


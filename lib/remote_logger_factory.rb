require 'drb/drb'

module Server
  class RemoteLogger
    include DRb::DRbUndumped

    delegate :close, :flush, :autoflushing, :autoflushing=, :level, :level=, :to => :logger
    delegate :log, :info, :debug, :error, :fatal, :to => :logger

    attr_reader :logger, :basedir, :log_name

    def initialize(log_name, basedir, options={})
      options.reverse_merge! :autoflush => 5, :keep => false
      @basedir = basedir
      @log_name = log_name
      path = File.join(basedir, log_name+'.log')
      system("cat /dev/null > #{path}") unless options[:keep]
      @logger = ActiveSupport::BufferedLogger.new(path)
      @logger.auto_flushing = options[:autoflush]
      @logger.level = options[:severity] ? options[:severity] : 0
      logger.info("Logging started at #{Time.now}\n")
      logger.flush
    end
  end

  class RemoteLoggerFactory

    attr_accessor :loggers

    def initialize()
      @loggers = { }
    end

    def get_logger(log_name, basedir, options={ })
      raise ArgumentError, "both log_name and basedir (first 2 args) must be specified!" if log_name.nil? || basedir.nil?
      log_name = log_name.gsub(/[.\/]/, "_").untaint
      if loggers.has_key? log_name
        if self.loggers[log_name].basedir == basedir
          loggers[log_name]
        else
          raise ArgumentError, "logger #{log_name} already exits with different directory: #{loggers[log_name].basedir}!"
        end
      else
        loggers[log_name] = RemoteLogger.new(log_name, basedir, options)
      end
    end

    def names()
      loggers.keys
    end

    def close(log_name)
      if loggers.has_key? log_name
        loggers[log_name].info("Logging terminated at #{Time.now}\n")
        loggers[log_name].close()
        loggers.delete log_name
      else
        raise ArgumentError, "no logger named #{log_name} found!"
      end
    end

    def close_all()
      loggers.keys.each { |log_name| close(log_name) }
    end
  end
end

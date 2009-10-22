# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'backtester'

module Backtest

  class BacktestrException
    def initialize(name)
      super("Problem with statement named: #{name}")
    end
  end

  class Builder

    attr_reader :options, :description, :backtests

    def initialize(options)
      @options = options
      @backtests = []
    end

    def using(entry_trigger_name, entry_strategy_name, exit_trigger_name, exit_strategy_name, scan_name, &block)
      @backtests << Backtester.new(entry_trigger_name,
                                   entry_strategy_name,
                                   exit_trigger_name,
                                   exit_strategy_name,
                                   scan_name,
                                   description, options, &block)
    end

    def desc(string)
      @description = string
    end

    # Doing a shift reduces the amount of garbage because we lose one off a global list each iter
    def run(logger)
      startt = Time.now
      pid_map = { }
      until backtests.empty?
        unless (backtest = backtests.shift).nil?
          puts "Forking #{backtest.scan_name}"
          pid = fork do
            begin
              backtest.run(logger)
            rescue ActiveRecord::StatementInvalid => e
              if e.to_s =~ /Lost connection/ || e.to_s =~ /away/
                ActiveRecord::Base.establish_connection
                puts "re-establishing connection for #{backtest.scan_name}"
                sleep(1)
                retry
              else
                raise e
              end
            rescue Exception => e
              if e.to_s =~ /Lost connection/ || e.to_s =~ /away/
                ActiveRecord::Base.establish_connection
                puts "re-establishing connection for #{backtest.scan_name}"
                sleep(1)
                retry
              else
                puts "FATAL error: (#{backtest.scan_name}) #{e.class}: #{e.to_s}"
                exit(1)
              end
            end
            exit()
          end
          pid_map[pid] = backtest
          sleep(1)
        end
      end
      bad_status_ary = Process.waitall.find_all { |pair| pair.last.exit_status != 0 }
      puts bad_status_ary.inspect

      endt = Time.now
      delta = endt - startt
      logger.info "#{backtests.length} Backtests run -- elapsed time: #{Backtester.format_et(delta)}"
    end
  end
end

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

    def run(logger)
      startt = Time.now
      chunk = BarUtils::Splitter.new(backtests)
      until chunk.items.empty?
        unless (backtest = chunk.items.shift).nil?
        #  begin
            backtest.run(chunk.id, logger)
        #  rescue Exception => e
        #    puts "FATAL error: (#{backtest.scan_name}) #{e.class}: #{e.to_s}"
        #    exit(1)
        #  end
        end
      end
      endt = Time.now
      delta = endt - startt
      logger.info "#{backtests.length} Backtests run -- elapsed time: #{Backtester.format_et(delta)}"
    end
  end
end

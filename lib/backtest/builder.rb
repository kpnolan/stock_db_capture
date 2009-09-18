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
      @backtests << Backtester.new(entry_trigger_name, entry_strategy_name, exit_trigger_name, exit_strategy_name, scan_name, description, options, &block)
    end

    def desc(string)
      @description = string
    end

    def run(logger)
      backtests.each do |backtest|
        #begin
          backtest.run(logger)
        #rescue Exception => e
        #  logger.error("FATAL error: #{e.to_s}")
        #end
      end
    end
  end
end

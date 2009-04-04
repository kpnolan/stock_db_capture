require 'ostruct'

module Backtest

  class BacktestrException
    def initialize(name)
      super("Problem with statement named: #{name}")
    end
  end

  class Builder
    def initialize()
      @applications = []
      @descriptions = []
    end

    def apply(strategy, populations, &block)
      raise ArgumentError.new("Block missing") unless block_given?
      populations = [ populations ] unless populations.is_a? Array
      @applications << OpenStruct.new(:strategy => strategy, :desc => @descriptions.shift,
                                      :populations => populations, :block => block)
    end

    def desc(string)
      @descriptions << string
    end

  end
end

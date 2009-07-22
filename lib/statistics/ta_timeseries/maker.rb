# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Statistics
  module TaTimeseries
    module Maker
      def self.indicators(name, options, &block)
        builder = Statistics::TaTimeseries::Builder.new(name, options)
        $indicator_families ||= []
        builder.instance_eval(&block)
        $indicator_families << builder
      end
    end
  end
end

def indicators(name, options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Statistics::TaTimeseries::Maker.indicators(name, options, &block)
end

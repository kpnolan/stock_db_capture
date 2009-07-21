# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Statistics
  module TaTimeseries
    module Maker
      def self.indicators(name, options, &block)
        $indcator_families ||= []
        $indicator_families << Statistics::TaTimeseries::Builder.new(name, options)
        builder.instance_eval(&block)
      end
    end
  end
end

def indicators(name, options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Statistics::TaTimeseries:Maker.indicators(name, options, &block)
end

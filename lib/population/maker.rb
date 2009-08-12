# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Population
  module Maker
    def self.populations(options, &block)
      $population = builder = Population::Builder.new(options)
      builder.extend(TechnicalAnalysis::ClassMethods)
      builder.instance_eval(&block)
    end
  end
end

def populations(options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Population::Maker.populations(options, &block)
end

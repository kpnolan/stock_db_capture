# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Statistics
  module Evaluator
    module Maker
      def self.run(options, &block)
        builder = Statistics::Evaluator::Builder.new(options)
        builder.instance_eval(&block)
        builder.run
      end
    end
  end
end

def run(options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Statistics::Evaluator::Maker.run(options, &block)
end

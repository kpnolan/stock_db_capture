# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Statistics
  module StudyComponents
    module Maker
      def self.study(name, options, &block)
        builder = Statistics::StudyComponents::Builder.new(name, options)
        builder.instance_eval(&block)
        builder.study.update_attribute(:description, builder.description) if builder.description
      end
    end
  end
end

def study(name, options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Statistics::StudyComponents::Maker.study(name, options, &block)
end

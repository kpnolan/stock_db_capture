module Statistics
  module Experiment
    module Maker
      def self.experiment(options, &block)
        $experiment = builder = Statistics::Experiment::Builder.new(options)
        builder.instance_eval(&block)
      end
    end
  end
end

def experiment(options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Statistics::Experiment::Maker.experiment(options, &block)
end

module Statistics
  module Experiment
    class ExperimentException < Exception
      def initialize(name)
        super("Problem with statement named: #{name}")
      end
    end

    class Builder

      attr_reader :options, :description, :experiments

      def initialize(options)
        @options = options
        @experiments = []
      end

      def run(study_name, options, &block)
        @experiments << Statistics::Experiment::Test.new(study_name, options, &block)
      end

      def execute(logger)
        $logger = logger
        experiments.each do |experiment|
          experiment.run()
        end
      end
    end
  end
end

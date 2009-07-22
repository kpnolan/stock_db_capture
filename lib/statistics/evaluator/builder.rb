# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Statistics
  module Evaluator

    class EvaluatorException
      def initialize(name)
        super("Problem with statement named: #{name}")
      end
    end

    class Builder

      attr_reader :options, :jobs

      def initialize(options={})
        @options = options
        @jobs = []
      end

      def apply(family, population, options={})
        @jobs << Statistics::Evaluator::Job.new(family, population, options)
      end

      def run(logger)
        jobs.each do |job|
          job.run(logger)
        end
      end
    end
  end
end

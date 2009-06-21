require 'yaml'
require 'ostruct'

module Statistics
  module StudyComponents
    class BuilderException < Exception
      def initialize(name)
        super("Problem with statement named: #{name}")
      end
    end

    class Builder

      attr_reader :study, :factors, :description

      def initialize(name, options)
        $study = @study = Study.create_with_version(name, options)
      end

      def factor(name, params={})
        Factor.create_from_args($study, name, params)
      end

      def desc(string)
        @description = string
      end
    end
  end
end

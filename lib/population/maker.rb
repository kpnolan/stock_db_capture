module Population
  module Maker
    def self.populations(options, &block)
      $population = builder = Population::Builder.new(options)
      builder.instance_eval(&block)
    end
  end
end

def populations(options={}, &block)
  raise ArgumentError.new("block not specified!") unless block_given?
  Population::Maker.populations(options, &block)
end

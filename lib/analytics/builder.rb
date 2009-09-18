# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'yaml'
require 'ostruct'

module Analytics

  class Hash
    # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
    #
    # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
    def to_yaml( opts = {} )
      YAML::quick_emit( object_id, opts ) do |out|
        out.map( taguri, to_yaml_style ) do |map|
          sort.each do |k, v|   # <-- here's my addition (the 'sort')
            map.add( k, v )
          end
        end
      end
    end
  end


  class BuilderException < Exception
    def initialize(name)
      super("Problem with statement named: #{name}")
    end
  end

  class Builder

    def initialize(options)
      @options = options
      @etriggers = []
      @xtriggers = []
      @openings = []
      @closings = []
      @stop_loss = nil
      @descriptions = []
    end

    def find_stop_loss(); @stop_loss; end
    def find_etrigger(name); @etriggers.find { |o| o.name == name }; end
    def find_xtrigger(name); @xtriggers.find { |o| o.name == name }; end
    def find_opening(name); @openings.find { |o| o.name == name }; end
    def find_closing(name); @closings.find { |c| c.name == name }; end

    def has_pair?(entry_strategy_name, exit_strategy_name)
      find_opening(entry_strategy_name) && find_closing(exit_strategy_name)
    end

    def entry_trigger(name, params={}, &block)
      raise ArgumentError.new("Block missing for open position #{name}") unless block_given?
      et = EntryTrigger.create_or_update!(name, @descriptions.shift, params.to_yaml)
      etrigger = OpenStruct.new
      etrigger.name = name
      etrigger.params = params
      etrigger.block = block
      @etriggers << etrigger
    end

    def open_position(name, params={}, &block)
      raise ArgumentError.new("Block missing for open position #{name}") unless block_given?
      es = EntryStrategy.create_or_update!(name, @descriptions.shift, params.to_yaml)
      opening = OpenStruct.new
      opening.name = name
      opening.params = params
      opening.block = block
      @openings << opening
    end

    def exit_trigger(name, params={}, &block)
      raise ArgumentError.new("Block missing for open position #{name}") unless block_given?
      et = ExitTrigger.create_or_update!(name, @descriptions.shift, params.to_yaml)
      xtrigger = OpenStruct.new
      xtrigger.name = name
      xtrigger.params = params
      xtrigger.block = block
      @xtriggers << xtrigger
    end

    def close_position(name, params={}, &block)
      raise ArgumentError.new("Block missing for close position #{name}") unless block_given?
      xs = ExitStrategy.create_or_update!(name, @descriptions.shift, params.to_yaml)
      closing = OpenStruct.new
      closing.name = name
      closing.params = params
      closing.block = block
      @closings << closing
    end

    def stop_loss(threshold, options={})
      raise ArgumentError, "Threshdold must a percentage between between 0 and 100" unless (0.0..100.0).include? threshold.to_f
      sloss = OpenStruct.new
      sloss.threshold = threshold.to_f
      sloss.options = options
      @stop_loss = sloss
    end

    def desc(string)
      @descriptions << string
    end
  end
end

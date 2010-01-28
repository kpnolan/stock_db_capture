# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'yaml'
require 'trading_calendar'

module Population

  extend TradingCalendar

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
    def initialize(name, msg)
      super("Problem with statement named: #{name}: #{msg}")
    end
  end

  class Builder

    attr_reader :options

    def initialize(options)
      @options = options
      @descriptions = []
      @scans = []
    end

    def find_scan(name)
      @scans.find { |tuple| tuple.first == name }
    end

    def desc(string)
      @descriptions << string
    end

    def prepare_attributes(options)
      cols = Scan.content_columns.map { |c| c.name.to_sym }
      options[:start_date] = options[:start_date].to_date
      options[:end_date] = options[:end_date].to_date
      options[:description] = @descriptions.shift
      options[:table_name] = 'daily_bars' if options[:table_name].nil?
      options[:prefetch] = options[:prefetch].to_i if options[:prefetch].is_a?(Numeric)
      options[:count] = options[:count].to_i if options[:count].is_a?(Numeric)
      options.reject { |key, value| ! cols.include? key }
    end

    def scan(name, options={})
      options.reverse_merge! :table_name => 'daily_bars'
      #begin
        name = name.to_s.downcase
        if (scan = Scan.find_by_name(name))
          attrs = prepare_attributes(options)
          scan.update_attributes!(attrs)
          @scans << scan
        else
          attrs = prepare_attributes(options)
          scan = Scan.create!({:name => name}.merge(options))
          @scans << scan
        end
      #rescue => e
      #  raise BuilderException.new(name, e.message)
      #end
    end
  end
end

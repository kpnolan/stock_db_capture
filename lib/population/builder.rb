require 'yaml'

module Population

  include TradingCalendar

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

    def scan(name, options={})
      begin
        name = name.to_s.downcase
        if (scan = Scan.find_by_name(name))
          options[:start_date] = Date.parse(options[:start_date])
          options[:end_date] = Date.parse(options[:end_date])
          options[:description] = @descriptions.shift
          options.reject { |key, value| [:start_date, :end_date, :description, :conditions, :join].include? key }
          scan.update_attributes!(options)
          @scans << scan
        else
          options[:start_date] = Date.parse(options[:start_date])
          options[:end_date] = Date.parse(options[:end_date])
          options[:description] = @descriptions.shift
          options.reject { |key, value| [:start_date, :end_date, :description, :conditions, :join].include? key }
          scan = Scan.create!({:name => name}.merge(options))
          @scans << scan
        end
      rescue => e
        raise BuilderException.new(name, e.message)
      end
    end
  end
end

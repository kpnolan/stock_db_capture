require 'yaml'

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

  class BuilderException
    def initialize(name)
      super("Problem with statement named: #{name}")
    end
  end

  class Builder
    def initialize()
      @strategies = []
      @descriptions = []
      @opennings = []
      @scans = []
    end

    def find_strategy(name)
      @strategies.find { |tuple| tuple.first == name }
    end

    def find_openning(name)
      @opennings.find { |tuple| tuple.first == name }
    end

    def strategy(name, params={}, &block)
      raise ArgumentError.new("Block missing for #{name}") unless block_given?
      if Strategy.find_by_name(name).nil?
        Strategy.create!(:name => name, :description => @descriptions.shift, :params_yaml => params.to_yaml)
      end
      @strategies << [name, params, block]
    end

    def open_position(name, params={}, &block)
      raise ArgumentError.new("Block missing for #{name}") unless block_given?
      if Strategy.find_by_name(name).nil?
        Strategy.create!(:name => name,  :description => @descriptions.shift, :params_yaml => params.to_yaml)
      end
      @opennings << [name, params, block]
    end

    def desc(string)
      @descriptions << string
    end

    def process_scans
      @scans.each do |pair|
        scan, changed = pair
        scan.tickers_ids if changed
      end
    end

    def scan(name, options={})
      begin
        if (scan = Scan.find_by_name(name))
          options[:start_date] = Date.parse(options[:start_date])
          options[:end_date] = Date.parse(options[:end_date])
          options[:description] = @descriptions.shift
          options.reject { |key, value| [:start_date, :end_date, :description].include? key }
          scan.update_attributes!(options)
          @scans << scan
        else
          options[:start_date] = Date.parse(options[:start_date])
          options[:end_date] = Date.parse(options[:end_date])
          options[:description] = @descriptions.shift
          options.reject { |key, value| [:start_date, :end_date, :description].include? key }
          scan = Scan.create!({:name => name}.merge(options))
          @scans << scan
        end
      rescue
        raise BuilderException.new(name)
      end
    end
  end
end

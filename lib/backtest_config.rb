# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'ruby-debug'
require 'yaml'
require 'tsort'
require 'thread'
require 'singleton'
require 'backtest/exceptions'
require 'backtest/result'

class Hash
  include TSort
  alias tsort_each_node each_key
  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end

  def to_mod
    hash = self
    Module.new do
      hash.each_pair do |key, value|
        define_method key do
          value
        end
      end
    end
  end
end

module BacktestConfig

  Declaration = Struct.new(:type, :name, :node_instance, :input, :outputs, :params, :meta_block, :block) do
    def initialize(type)
      self.type = type
    end
  end

  def BacktestConfig.load(cfg_file)
    unless cfg_file[0] = '/'
      path = File.join(RAILS_ROOT, 'btest', cfg_file)
    else
      path = cfg_file
    end
    config = ConfigDSL.instance()
    config.instance_eval(File.read(path), path, 1)
    config.validate_semantics()
  end

  class ConfigDSL
    include Singleton

    class ScanDecl < Declaration
      extend Forwardable
      def_delegators :@db_rec, :start_date, :end_date, :adjusted_start, :adjusted_ent, :year, :population_ids

      attr_accessor :db_rec

      def initialize()
        super(:scan)
      end

      def start_date()
        db_rec.start_date
      end

      def end_date
        db_rec.end_date
      end
    end

    attr_reader :options, :sources, :scans, :node_hash, :current_node, :tsort

    def initialize()
      @options = Hash.new
      @node_hash = Hash.new
      @tsort = []
      @late_bindings = []
      @post_process = Proc.new { }
      @stop_loss = []
      @scans = []
      @sources = []
    end

    def lookup_node(name, type=nil)
      node = node_hash[name]
      raise Backtest::ConfigException, "runtime type '#{type}' doesn't agree with config type '#{node.type}'" unless type.nil? || node.type == type
      node
    end

    def record_params(node)
      raise Backest::ConfigException, "#{node.name} has already been specified -- choose a unique name" unless @node_hash[node.name].nil?
      @node_hash[node.name] = node
      node.outputs = node.params.fetch(:outputs) { raise Backtest::ConfigException, "a (possibly empty) array of outputs must be specified for #{node.name}" }
    end

    def validate_semantics()
      @tsort = form_graph_and_tsort()
      tsort.each do |node_name|
        node = node_hash[node_name]
        node.outputs.each { |child| node_hash[child].input = node }
      end
      resolve_late_bindings()
      self
    end

    def resolve_late_bindings
      @late_bindings.each do |node|
        case node.params[:template]
        when :confirm then node.meta_block = confirmation_template(node.name, node.params, &node.block)
        when :displace then node.meta_block = displacement_template(node.name, node.params, &node.block)
        else
          raise Backtest::ConfigException, "filter node is neither displacement or confirmation"
        end
      end
    end

    def [](label)
      node_hash[label]
    end

    def parent(node_name)
      node_hash[node_name].input
    end

    def next_nodes(curr_node)
      curr_node.outputs.map { |name| node_hash[name] }
    end

    def next_id_pairs(curr_node)
      next_nodes(curr_node).map { |node| [node.type, node.name] }
    end

    def form_graph_and_tsort()
      graph = {}
      node_hash.each_pair do |k,node|
        graph[k] = node.outputs
      end
      @tsort = graph.tsort.reverse
    end

    def source(name, params, &block)
      raise ArgumentError.new("Block missing for Source #{name}") unless block_given?
      node = Declaration.new :source
      node.name = name
      node.params = params
      node.block = block
      node.meta_block = wrapper_template(params, &block)
      record_params(node)
      @sources << node
    end

    def open(name, params, &block)
      node = Declaration.new :open
      node.name = name
      node.params = params
      record_params(node)
      node.block = block
      node.meta_block = wrapper_template(params, &block) if params[:template].nil? || params[:template] == :none
    end

    def filter(name, params, &block)
      raise ArgumentError.new("Block missing for Filter #{name}") unless block_given?
      raise ArgumentError.new(":window param missing for Filter #{name}") unless params[:window]
      node = Declaration.new :filter
      node.name = name
      node.params = params
      record_params(node)
      node.block = block
      @late_bindings << node
    end

    def exit(name, params, &block)
      node = Declaration.new :exit
      node.name = name
      node.params = params
      record_params(node)
      node.block = block
      node.meta_block = wrapper_template(params, &block) if params[:template].nil? || params[:template] == :none
    end

    def close(name, params, &block)
      node = Declaration.new :close
      node.name = name
      node.params = params
      record_params(node)
      node.block = block
      node.meta_block = wrapper_template(params, &block) if params[:template].nil? || params[:template] == :none
    end

    def ScanDecl(name, params, &block)
      node = Declaration.new :scan
      node.name = name
      node.params = params
      record_params(node)
      node.block = block
      node.meta_block = wrapper_template(params, &block)
    end

    def global_options(options)
      @options = options.reverse_merge :resolution => 1.day, :price => :close, :log_flags => :basic,
                                       :pre_buffer => 0, :post_buffer => 0, :repopulate => true, :max_date => (Date.today-1),
                                       :record_indicators => false, :debug => false
      #create readers for each of the above options
      self.extend self.options.to_mod
    end

    def post_process(&block)
      @post_process = block
    end

    def stop_loss(threshold, options={})
      raise ArgumentError, "Threshdold must a percentage between between 0 and 100" unless (0.0..100.0).include? threshold.to_f
      sloss = Declaration.new :stop_loss
      sloss.threshold = threshold.to_f
      sloss.options = options
      @stop_loss = sloss
    end

    def prepare_scan_attributes(options)
      cols = Scan.content_columns.map { |c| c.name.to_sym }
      options[:start_date] = options[:start_date].to_date
      options[:end_date] = options[:end_date].to_date
      options[:prefetch] = options[:prefetch].to_i if options[:prefetch].is_a?(Numeric)
      options[:count] = options[:count].to_i if options[:count].is_a?(Numeric)
      options.reject { |key, value| ! cols.include? key }
    end

    def scan(name, params={}, &block)
      params.reverse_merge! :table_name => 'daily_bars'
      scan = ScanDecl.new
      scan.name = name.to_s.downcase
      scan.params = params
      record_params(scan)
      scan.block = block
      scan.meta_block = wrapper_template(params, &block)
      #begin
        if (scan.db_rec = Scan.find_by_name(scan.name))
          attrs = prepare_scan_attributes(params)
          scan.db_rec.update_attributes!(attrs)
        else
          attrs = prepare_scan_attributes(scan.options)
          scan.db_rec = Scan.create!({:name => name}.merge(params))
        end
      #rescue => e
      #  raise BuilderException.new(name, e.message)
      #end
      @scans << scan
    end

    def source_template(label, params, &block)
      #block.call()
    end

   def confirmation_template(name, params, &block)
     raise Backtest::ConfigException, "Filter nodes must include a :window param for #{name}" if params[:window].nil?
     sdate_method = start_date_field(name)
     time_span = params[:window]
      lambda do |position|
       # TODO which start time do we use ettime, entry_date, xttime?
       start_date = position.send(sdate_method).to_date
       max_exit_date = Position.trading_date_from(start_date, time_span)
       if max_exit_date > Date.today-1
         ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
         max_exit_date = ticker_max.localtime
       end
       begin
         ts = Timeseries.new(position.ticker_id, start_date..end_date, resolution)
         confirming_index = ts.instance_exec(params, &block)
         if confirming_index.nil?
           position.destroy
           return nil
         end
       rescue TimeseriesException => e
         puts e.to_s
         position.destroy
         return nil
       end
       confirming_index
     end
   end

    def wrapper_template(params, &block)
      lambda do |position|
        retval = block.call(params, position)
      end
    end

    def result_template(params, &block)
      lambda do |position, result_ary|
        retval = block.call(position, result_ary)
      end
    end

    def displacement_template(name, params, &block)
      raise Backtest::ConfigException, "Filter nodes must include a :window param for #{name}" if params[:window].nil?
      sdate_method = start_date_field(name)
      time_span = params[:window]
      lambda do |position|
        begin
          start_date = position.send(sdate_method).to_date
          max_exit_date = Position.trading_date_from(start_date, time_span)
          if max_exit_date > Date.today-1
            ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
            max_exit_date = ticker_max.localtime
          end
          #puts "calling timeseries with #{position.ticker.symbol} #{start_date}..#{max_exit_date}"
          ts = Timeseries.new(position.ticker_id, start_date..max_exit_date,resolution, self.options.merge(:logger => logger))

          result = ts.instance_exec(params, &block)
          #puts "ts result: #{result.join(', ')}"
          result
        rescue TimeseriesException => e
          puts e.to_s
          position.destroy
          nil
        rescue ActiveRecord::StatementInvalid
          position.destroy
          nil
        end
      end
    end
    #
    # Wait for a result targeted to the named block and position to show up. When it does (there is in reality no real
    # waiting because the result is sent before the messate to execute the output (receiver of the result).
    # So far, there are two kinds of results: a binary confirmation and a displacement result which yeilds
    # the a Time, a Trice, an Indicator and Indicator Value
    #
    def take_results_for(name, position)
      result = Backtest::Result.receive(name, position)
      result.decode()
    end

    def start_date_field(curr_label)
      input_node = parent(curr_label)
      case input_node.type
        when :source : :ettime
        when :open   : :entry_date
        when :filter : raise Backtest::ConfigException, "unknown start date for timeseries for Filter Node: #{curr_label}"
        when :exit   : :xttime
        when :close  : raise Backtest::ConfigException, "unknown start date for timeseries for Close Node: #{curr_label}"
        when nil     : raise Backtest::ConfigException, "unknown parent node of #{curr_label}"
      end
    end
  end
end

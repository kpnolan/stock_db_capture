require 'rinda/ring'

module Backtest
  #
  # A Message is the means of communication between nodes (stages). A Message is a tuple of the form
  #     [ node_type, node_name, ticker_id, time_sec, indicator_id ]
  # When a message is received the node_name is used to map to a node (the type is also checked). Nodes contain a
  # reference to a meta-block and a block. The meta-block is a Proc consisting of the body of one of several templates:
  # a simple wrapper which wraps the block given in the config file, a comfirmation block which executes the block in the
  # config file which returns a confirmation index or nil. Otherwise the meta-block is calls for a side effect write to the
  # given position.
  #
  Message = Struct.new(:type, :name, :position, :node_instance, :params, :block, :meta_block) do
    def initialize(ary)
      self.type, self.name, ticker_id, time_sec, etind_id = ary
      self.position = Position.find_tuple(ticker_id, time_sec, etind_id)
      self.node_instance = node = BacktestConfig::ConfigDSL.instance.lookup_node(name, type)
      self.block = node.block
      self.meta_block = node.meta_block
    end

    def to_s
      "[ #{type}, #{name}, "
    end

    def eval_body(context)
      b = self.meta_block
      $stdout.puts "calling meta-block...for  #{node_instance.type}:#{node_instance.name}"
      context.instance_exec(position, &b)
    end

    def body?()
      meta_block && block
    end

    def interpret_results(results)
      #if results.is_a?(Array)
      #  puts "in interpret results:  #{results.join(', ')}"
      #else
      #  puts "in interpret results: result(#{results})"
      #end
      case
      when results.nil? && params[:template] == :confirm then nil
      when results.is_a?(Array) && params[:template] == :displace && validate_results(results)
        #
        # Send results to any and all outputs declared for this block
        #
        #puts "results are VALID"
        params[:outputs].each do |name|
          #puts "recording result for #{name}"
          Result.record(name, position, results)
        end
        true
      when results.is_a?(Array) && params[:template] != :displace
        raise Backtest::RuntimeException, "Array returned on non-displacement node #{node_instance.name}"
      when node_instance.type == :open then true
      when node_instance.type == :exit then true
      when results.nil? && params[:template] != :confirm
        raise Backtest::RuntimeException, "nil result for type #{node_instance.type}:#{node_instance.name} (non-confirmation node)"
      end
    end

    def validate_results(results)
      unless results[0].is_a?(Time) && results[1].is_a?(Numeric) && results[2].is_a?(Symbol) && results[3].is_a?(Numeric)
        raise Backtest::RuntimeException, "malformed tuple on dsiplacement node #{node_instance.name} result is not a displacement array -- #{results.join(', ')}"
      end
      true
    end

    # Send this message to stage named by node_name
    def send_to_stage(node_name)
      raise ArgumentError, "configuration has not been bound" if @@config.nil?
      raise ArgumentError, "tuplespace has not been bound" if @@tuplespace.nil?
      node = @@config[node_name]
      debugger if node.nil?
      @@tuplespace.write([node.type, node.name, *position.tuple_id])
    end
  end

  # Wait for position message
  def Message.receive(node, timeout=@@default_timeout)
    raise ArgumentError, "typlespace has not been bound" if @@tuplespace.nil?
    msg = Message.new(@@tuplespace.take([node.type, node.name, nil, nil, nil], @@default_timeout))
    node = BacktestConfig::ConfigDSL.instance.lookup_node(msg.name, msg.type)
    msg.node_instance = node
    msg.params = node.params
    msg
  end

  def Message.bind_to_tuplespace(tuplespace)
    @@tuplespace = tuplespace
  end

  def Message.bind_to_config(config)
    @@config = config
  end

  def Message.default_timeout=(timeout)
    @@default_timeout = timeout
  end

  def Message.read(type=nil, name=nil)
    raise ArgumentError, "typlespace has not been bound" if @@tuplespace.nil?
    @@tuplespace.read(type, name, nil, nil, nil)
  end

  def Message.dump_all(type=nil, name=nil)
    tuples = read_all(type, name)
    count = tuples.length
    tuples.each do |tuple|
      puts "[ #{tuple.join(',')} ]"
    end
    puts "#{count} Message tuples found"
  end

  def Message.read_all(type=nil, name=nil)
    raise ArgumentError, "typlespace has not been bound" if @@tuplespace.nil?
    @@tuplespace.read_all([type, name, nil, nil, nil])
  end

  def Message.default_timeout
    @@default_timeout
  end
end


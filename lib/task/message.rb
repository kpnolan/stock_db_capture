require 'rinda/ring'
require 'class_helpers'

module Task
  #
  # A Message is the means of communication between nodes (stages). A Message is a tuple of the form
  #     [ node_type, node_name, ticker_id, time_sec, indicator_id ]
  # When a message is received the node_name is used to map to a node (the type is also checked). Nodes contain a
  # reference to a meta-block and a block. The meta-block is a Proc consisting of the body of one of several templates:
  # a simple wrapper which wraps the block given in the config file, a comfirmation block which executes the block in the
  # config file which returns a confirmation index or nil. Otherwise the meta-block is calls for a side effect write to the
  # given position.
  #
  class Message
    attr_reader :curr_task, :target_tasks, :options, :payload, :raw_args, :decoded_args
    cattr_accessor :fabric, :config, :logger
    cattr_accessor_with_default :check, true
    cattr_accessor_with_default :default_timeout, 30

    delegate :info, :error, :debug, :to => :logger

    alias :task_args :decoded_args

    def initialize(task, raw_args, options={})
      raise ArgumentError, "configuration has not been bound" if config.nil?
      raise ArgumentError, "messaging fabric has not been bound" if fabric.nil?
      @raw_args = raw_args
      @options = options.reverse_merge :transcode => :encode, :timeout => default_timeout
      @curr_task = task
      @target_tasks = task.targets.map do |task_name|
        task = config.lookup_task(task_name)
        raise Task::Config::Runtime::MsgException, "Uknown task #{task_name} specifed for Message.initialize()" if task.nil?
        task
      end

      if check && options[:transcode] == :encode && target_tasks.length > 1
        parent = task
        target_tasks = target.target_tasks

        if target_tasks.any? { |task| task.parent != parent }
          rejects = target_tasks.reject { |task| task.parent == parent }
          reject_names = rejects.map(&:name)
          raise Task::Config::Runtime::MsgException, "the following tasks have belong to differrent parents #{reject_names.join(',')}"
        end

        if target_tasks.any? { |task| parent.outputs != task.inputs }
          rejects = target_tasks.reject { |task| parent.outputs == task.inputs }
          reject_names = rejects.map(&:name)
          msg = "the following tasks have mismatched types output sig: #{parent.outputs} #{reject_names.join(',')}"
          raise Task::Config::Runtime::MsgException, msg
        end
      end

      method = options[:transcode] == :decode ? :decoded_args= : :payload=
      send(method, raw_args)
    end

    def payload=(raw_args)
      @payload = curr_task.encode_payload(raw_args)
    end

    def decoded_args=(raw_array)
      @decoded_args = curr_task.decode_payload(raw_array)
    end

    def to_s
      "[ #{target_task.name}, "
    end

    # Send this message to the tasks provided at contruction with the passed args encoded as the payload
    def deliver()
      raise Task::Config::Runtime::MsgException,  "Message created w/o specifying any targets" if target_tasks.nil? || target_tasks.empty?
      target_tasks.each do |task|
        payload.unshift(task.name)
        #set_trace_func proc { |event, file, line, id, binding, classname|
        #  printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
        #}
        fabric.write(payload)
        #set_trace_func(nil)
        payload.shift
      end
    end
  end

  # Wait for position message
  def Message.receive(task, timeout=default_timeout)
    raise ArgumentError, "messaging fabic has not been bound" if fabric.nil?
    #
    # Since we a desctructing instances of Class to an array, we can't use a type signature here. Instead we will wait
    # on wildcards
    # TODO memoize the Array of nils so that we don't make a lot of garbage
    #
    signature = Array.new(task.proxied_input_signature.length, nil)
    #logger.debug "Rinda wating for tuple pattern: #{[task.name, *signature].inspect}"
    raw_args = fabric.take([task.name, *signature], timeout).drop(1)
    #logger.debug "Got it! #{[task.name, raw_args.inspect]}"
    msg = Message.new(task, raw_args, :transcode => :decode)
  end

  def Message.read(name)
    raise ArgumentError, "messaging fabric has not been bound" if fabric.nil?
    task = config.lookup_task(name)
    raise Task::Config::Runtime::MsgException, "Uknown task #{name} specifed for Message.read_()" if task.nil?
    payload = fabric.read([name, *task.inputs])
  end

  def Message.dump_all(name, arg_count, count_only=false)
    raise ArgumentError, "messaging fabric has not been bound" if fabric.nil?
    arg_template = Array.new(arg_count, nil)
    arg_template.unshift(name)
    tuples = fabric.read_all(arg_template)
    count = tuples.length
    tuples.each do |tuple|
      puts tuple.inspect unless count_only
    end
    if count.zero?
      puts "No :#{name} messages found"
    else
      puts unless count_only
      puts "#{count} :#{name} messages found"
      puts unless count_only
    end
  end

  def Message.read_all(name)
    raise ArgumentError, "typlespace has not been bound" if fabric.nil?
    task = config.lookup_task(name)
    raise Task::Config::Runtime::MsgException, "Uknown task #{name} specifed for Message.read_all()" if task.nil?
    payload = fabric.read([name, *task.inputs])
  end

  def Message.bind_to_message_fabric(msg_fabric, options={})
    self.fabric = msg_fabric
  end

  def Message.attach_logger(logger)
    self.logger = logger
  end

  def Message.bind_to_config(config)
    self.config = config
  end
end

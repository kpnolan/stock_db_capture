require 'class_helpers'

module Task
  #
  # A Message is the means of communication between nodes (stages). The data in a message is a Proxied form of the
  # underlying object, generally to consume less space. Most "live" objects have transient state which can be reconstructed
  # on the receiving end.
  #
  # When a message is received the node_name is used to map to a node (the type is also checked). Nodes contain a
  # reference to a meta-block and a block. The meta-block is a Proc consisting of the body of one of several templates:
  # a simple wrapper which wraps the block given in the config file, a comfirmation block which executes the block in the
  # config file which returns a confirmation index or nil. Otherwise the meta-block is calls for a side effect write to the
  # given position.
  #
  class Message
    attr_reader :task, :target_tasks, :options, :payload, :proxy, :restored_obj, :opaque_obj

    cattr_accessor :config, :logger
    cattr_accessor_with_default :sent_messages, 0
    cattr_accessor_with_default :to_task_count, { }
    cattr_accessor_with_default :received_messages, 0
    cattr_accessor_with_default :check, true

    delegate :info, :error, :debug, :to => :logger

    def initialize(task, opaque_obj, options={})
      raise ArgumentError, "configuration has not been bound" if config.nil?
      @opaque_obj = opaque_obj
      @options = options.reverse_merge :transcode => :encode
      @task = task
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
      end
      method = options[:transcode] == :decode ? :decoded_args= : :payload=
      send(method, opaque_obj)
    end

    def payload=(opaque_obj)
      @proxy = task.encode_proxy(opaque_obj)
      @payload = Marshal.dump(proxy)
    end

    def decoded_args=(proxy)
      @proxy = proxy
      @restored_obj = task.decode_proxy(proxy)
    end

    # Send this message to the tasks provided at contruction with the passed args encoded as the payload
    def deliver(pool)
      raise Task::Config::Runtime::MsgException,  "Message created w/o specifying any targets" if target_tasks.nil? || target_tasks.empty?
      target_tasks.each do |task|
        name = task.name
        Message.sent_messages += 1
        pool[name][payload]
        @@to_task_count[name] ||= 0
        @@to_task_count[name] += 1
      end
    end
  end

  def Message.receive(task, marshaled_str)
    self.received_messages += 1
    proxy = Marshal.load(marshaled_str)
    msg = Message.new(task, proxy, :transcode => :decode)
  end

  def Message.attach_logger(logger)
    self.logger = logger
  end

  def Message.bind_config(config)
    self.config = config
  end
end

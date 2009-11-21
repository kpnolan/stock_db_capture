# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'ostruct'
require 'pp'
require 'stringio'

module Kernel
  private
  def pp_s(*objs)
      s = StringIO.new
      objs.each {|obj|
        PP.pp(obj, s)
      }
      s.rewind
      s.read
  end
  module_function :pp_s
end

module Sim
  class ConfigurationMgr

    attr_reader :options

    def initialize(sm, ostruct)
      master_config, local_config = {}, {}
      master_path = File.join(RAILS_ROOT, 'lib', 'sim', 'config.yml')
      user_path = File.join(ENV['USER'], '.satvatr', 'simulator.yml')
      master_config = YAML.load_file(master_path) if File.exists? master_path
      local_config = YAML.load_file(user_path) if File.exists? user_path
      default_options = master_config.merge(local_config)
      @options = OpenStruct.new(default_options.merge(ostruct.marshal_dump))
      sm.log("Config Values for Simulation are: \n\n")
      sm.log(pp_s(options.marshal_dump))
    end

    def cval(key)
      options.send(key)
    end
  end
end

#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'ostruct'
require 'yaml'
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
      if ostruct.apply_defaults
        master_config, local_config = {}, {}
        master_path = File.join(RAILS_ROOT, 'lib', 'sim', 'config.yml')
        user_path = File.join(ENV['USER'], '.satvatr', 'simulator.yml')
        master_config = YAML.load_file(master_path) if File.exists? master_path
        local_config = YAML.load_file(user_path) if File.exists? user_path
        default_options = master_config.merge(local_config).inject({}) { |m, pair| m[pair.first.to_sym] = pair.second; m}
        @options = OpenStruct.new(default_options.merge(ostruct.marshal_dump))
      else
        @options = ostruct
      end
      sm.log("Config Values for Simulation are: \n\n")
      sm.log(pretty_options(options.marshal_dump))
    end

    def cval(key)
      options.send(key)
    end

    def pretty_options(option_hash)
      option_hash.to_yaml
    end
  end
end

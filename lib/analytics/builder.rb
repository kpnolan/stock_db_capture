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

require 'yaml'
require 'struct'

module BacktestConfig

  Declaration = Struct.new(:type, :name, :input, :params, :block) do
    def initialize(type)
      self.type = type
    end
  end

  class BuilderException < Exception
    def initialize(name)
      super("Problem with statement named: #{name}")
    end
  end

  class Builder

    attr_reader options, sources, openings, filters, exits, closings, scans

    def initialize(config_file)
      @options = Hash.new
      @label_hash = Hash.new
      @input_hash = Hash.new
      @sources = []
      @openings = []
      @filters = []
      @exits = []
      @closings = []
      @scans = []
      @post_process = Proc.new
      @stop_loss = []
      load(config_file)
      debugger
      a=1
    end

    def record_params(decl, need_input=true)
      raise BuilderException, "#{decl.name} has already been specified -- choose a unique name" unless @label_hash[decl.name].nil?
      @label_hash[decl.name] = decl
      input = decl.params.delete(:input) { raise BuilderException, "input must be specified for #{decl.type} #{decl.name}" } if need_input
      @input_hash[decl.name] = input
      decl
    end

    def get_type(name)
      if (decl = @label_hash[name]).nil?
        nil
      else
        decl.type
      end
    end

    def source(name, params, &block)
      raise ArgumentError.new("Block missing for Source #{name}") unless block_given?
      source = Declaration.new :source
      source.name = name
      source.params = params
      source.block = block
      @sources << record_params(source, false)
    end

    def open(name, params, &block)
      opening = Declaration.new :open
      opening.name = name
      opening.params = params
      opening.input = params.delete :input
      opening.block = block
      @openings << record_params(opening)
    end

    def filter(name, params, &block)
      raise ArgumentError.new("Block missing for Filter #{name}") unless block_given?
      filter = Declaration.new :filter
      filter.name = name
      filter.params = params
      filter.block = block
      @filters << record_params(filter)
    end

    def exit(name, params, &block)
      exit = Declaration.new :filter
      exit.name = name
      exit.params = params
      exit.block = block
      @exits << record_params(exit)
    end

    def close(name, params, &block)
      closing = Declaration.new :close
      closing.name = name
      closing.params = params
      closing.block = block
      @closings << record_params(closing)
    end

    def scan(name, params)
      scan = Declaration.new :scan
      scan.name = name
      scan.params = params
      scan.block = block
      @scans << record_params(scan, false)
    end

    def global_options(options)
      @options.reverse_merge! options
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
  end
end

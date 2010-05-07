#!/usr/bin/env ruby
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

#
# This Ugly piece of code just addes the absolute path RAILS_ROOT
#
root_path_ary = File.expand_path(File.dirname(__FILE__)).split('/') + ['..','..']
root_dir = File.expand_path(File.join(root_path_ary))

require 'rubygems'
require 'optparse'
require 'ostruct'
require File.join(root_dir,'config/mini-environment')

options = OpenStruct.new

optparse = OptionParser.new do |opts|
  opts.banner = "Usage task_manager start -- [options]"

  opts.on('-C', '--config FILE', String, "The task config file") do |config_file|
    options.config_file = config_file
  end

  options.server_count = 1
  opts.on('-s', '--servers NUMBER', Integer, "Fork NUMBER of task servers") do |s|
    options.server_count = s
  end

  options.process_index = 1
  opts.on('-i', '--proc_id NUMBER', Integer, "Index of the forked proces") do |i|
    options.process_index = i
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end

optparse.parse!
unless options.config_file
  puts 'config file is MANDITORY!'
else
  puts "Running #{options.server_count} processes"
  Task::Base.run(options.config_file, options.process_index)
end

# Local Variables:
# mode:ruby
# End:

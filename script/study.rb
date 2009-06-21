#!/usr/bin/env ./script/runner

require 'statistics/base'
include Statistics::Experiment

proc_count = 1

if ARGV.empty?
   puts "Usage: ./script/study.rb <experiment config file>"
   exit()
end

require File.dirname(__FILE__) + "/../config/#{ARGV[0]}.rb"

logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', "#{ARGV[0]}_experiment.log"))

#begin
  $experiment.execute(logger)
#rescue => e
#  puts e.message
#  raise BacktestException.new("Backtest cancelled because of previous errors")
#end





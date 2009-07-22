#!/usr/bin/env ./script/runner

require 'statistics/tits_base'

include Statistics::Evaluator

proc_count = 1

if ARGV.empty?
   puts "Usage: ./script/tits <tits config file>"
   exit()
end

require File.dirname(__FILE__) + "/../btest/#{ARGV[0]}.rb"

logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', "#{ARGV[0]}_tits.log"))

#begin
  $evaluator.run(logger)
#rescue => e
#  puts e.message
#  raise BacktestException.new("Backtest cancelled because of previous errors")
#end





#!/usr/bin/env /work/tdameritrade/stock_db_capture/script/runner

ENV['RAILS_ENV'] = 'production'
#RAILS_ENV = 'production'

sigma = 2.0

if ARGV[0] == '-h'
  puts "Usage: histo_plot.rb <strategy> <opt_sigma>"
  exit
end
puts "strategy must be given as the first arg" if ARGV[0].nil?
sigma = ARGV[1].to_f unless ARGV[1].nil?

require 'analyze_returns'

AnalyzeReturns.nreturn_histogram(ARGV[0], sigma)




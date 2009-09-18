#!/usr/bin/env /work/railsapps/stock_db_capture/script/runner

ENV['RAILS_ENV'] = 'production'
#RAILS_ENV = 'production'

sigma = 2.0

if ARGV[0] == '-h'
  puts "Usage: histo_plot.rb <value> <opt_sigma>?"
  exit
end
puts "Value of position must be given as the first arg" if ARGV[0].nil?
sigma = ARGV[1].to_f unless ARGV[1].nil?

require 'analyze_returns'

AnalyzeReturns.position_histogram(ARGV[0], sigma)




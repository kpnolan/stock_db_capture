#!/usr/bin/env /work/railsapps/stock_db_capture/script/runner

ENV['RAILS_ENV'] = 'production'
#RAILS_ENV = 'production'

sigma = 2.0
val = 'nreturn'

case
  when ARGV[0] == nil : puts "Usage: histo_plot.rb <value> <opt_sigma>"
  when ARGV[0] != nil : val = ARGV[0]
  when ARGV[1] != nil : sigma = ARGV[1].to_f
end


require 'analyze_returns'

AnalyzeReturns.nreturn_histogram(val, sigma)




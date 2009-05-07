#!/usr/bin/env /work/railsapps/stock_db_capture/script/runner

ENV['RAILS_ENV'] = 'production'
#RAILS_ENV = 'production'



require 'analyze_returns'

AnalyzeReturns.nreturn_histogram()
AnalyzeReturns.nreturn_pdf()



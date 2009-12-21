# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

#require 'rubygems'
#require 'bar_utils'

#extend BarUtils

namespace :active_trader do
  namespace :rdata do
    desc "Generate Target RSI Study"
    task :rsi_targets => :environment do
      logger = init_logger(:rsi_targets)
      RsiTargetStudy.generate(logger)
    end
  end
end

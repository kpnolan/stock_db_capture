# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'build_shadow'

namespace :active_trader do
  desc "generate show methods for ta-lib"
  task :generate_ta_shadow_methods do
    BuildShadow.generate_shadow_file('technical_analysis.rb')
  end
end

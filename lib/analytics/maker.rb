# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'

module Analytics
  module Maker
    def self.analytics(options, &block)
      $analytics = builder = Analytics::Builder.new(options)
      builder.instance_eval(&block)
    end
  end
end

def analytics(options={}, &block)
  Analytics::Maker.analytics(options, &block)
end

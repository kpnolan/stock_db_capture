# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class ConfigurationMgr

    attr_reader :options

    def initialize(options)
      @options = options
    end
  end
end

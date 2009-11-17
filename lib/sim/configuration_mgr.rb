# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class ConfigurationMgr

    def initialize()
      @master_config = YAML.load_file(File.join(RAILS_ROOT, 'lib', 'sim', 'config.yml'))
    end

    def config_hash(klass)
      path = klass.to_s.underscore
      class_part = path[/^sim\/(.+)/, 1]
      @master_config[class_part]
    end

    def raw_cval(klass, key)
      config_hash(klass)[key.to_s]
    end
  end
end

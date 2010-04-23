module Backtest
  #
  # raise only during a "validate" or during the load of the bactest config file
  #
  class ConfigException < Exception
    def initialize(msg)
      super(msg)
    end
  end
  #
  # raise only when runing a backtest Base process/thread
  #
  class RuntimeException < Exception
    def initialize(msg)
      super(msg)
    end
  end
end

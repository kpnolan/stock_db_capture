# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class PositionCloser < Subsystem

    def initialize(sm, cm)
      super(sm, cm, self.class)
    end

    def sell_mature_positions()
      count = 0
      for sim_pos in mature_positions()
        close(sim_pos)
        count += 1
      end
      count
    end

    def close(sim_pos)
      sell_order = sell(sim_pos)
    end
  end
end

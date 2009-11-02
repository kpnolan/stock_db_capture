module Sim
  class PositionCloser < Subsystem

    def initialize(sm)
      super(sm, self.class)
    end

    def sell_mature_positions()
      for sim_pos in mature_positions()
        close(sim_pos)
      end

      def close(sim_pos)
        sell_order = sell(sim_pos)
      end
    end
  end
end

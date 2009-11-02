module Sim
  class Chooser < Subsystem

    def initialize(sm)
      super(sm, self.class)
    end

    def find_candidates(date, count)
      pool = Position.cheap.find_by_date(:entry_date, date, :order => 'entry_price')
      pool.length < count ? pool : pool[0..count]
    end
  end
end

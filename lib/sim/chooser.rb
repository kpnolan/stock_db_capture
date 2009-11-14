module Sim
  class Chooser < Subsystem

    attr_reader :pool_behavior

    def initialize(sm, cm)
      super(sm, cm, self.class)
      @scopes = {}
      #add_scopes()
    end

    def add_scopes()
      add_scope(:cheap15, Position.scoped(:conditions => { :entry_price => 1.0..15.0 }))
      add_scope(:cheap30, Position.scoped(:conditions => { :entry_price => 1.0..30.0 }))
    end

    def add_scope(name, scope)
      @scopes[name] = scope
    end

    def find_candidates(date, count)
      pool = Position.normal.find_by_date(:entry_date, date, :limit => count)
      pool
    end
  end
end

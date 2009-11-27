# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class EventLogger < Subsystem

    attr_reader :levels, :logger

    def initialize(sm, cm)
      super(sm, cm, self.class)

      path = File.join(output_dir, (cval(:prefix) ? cval(:prefix)+'_' : cval(:position_table)+'_'))
      path << 'sim_events.log'
      File.truncate(path, 0)
      @logger = ActiveSupport::BufferedLogger.new(path)
      @levels = case cval(:log_level)
                when 0 : []
                when 1 : [SimSummary]
                when 2 : [SimSummay, SimPosition]
                else
                  []
                end

      sep()
    end

    def log_event(obj_or_str)
      if obj_or_str.is_a?(ActiveRecord::Base)
        logger.info("#{obj_or_str.event_time.to_formatted_s(:ymd)} #{obj_or_str.to_s}") if levels.include?(obj_or_str.class)
      else
        logger.info(obj_or_str)
      end
      obj_or_str
    end

    def sep()
      logger.info('')
    end
  end
end

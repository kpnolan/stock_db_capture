# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module Sim
  class EventLogger

    attr_reader :levels, :cm, :logger

    def initialize(cm)
      @cm = cm
      path = File.join(RAILS_ROOT, 'log', (cval(:prefix) ? cval(:prefix)+'_' : cval(:position_table)+'_'))
      @logger = ActiveSupport::BufferedLogger.new(path+'sim_events.log')
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

private

    def cval(key)
      cm.options.send(key)
    end
  end

  def self.log_event(obj_or_str)
    $el.log_event(obj_or_str)
  end
end

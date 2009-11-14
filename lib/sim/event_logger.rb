module Sim
  class EventLogger
    include Singleton

    attr_reader :levels

    def initialize()
      @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'sim_events.log'))
      sep()
    end

    def set_levels(levels)
      @levels = levels
    end

    def log_event(obj_or_str)
      if obj_or_str.is_a?(ActiveRecord::Base)
        @logger.info("#{obj_or_str.event_time.to_formatted_s(:ymd)} #{obj_or_str.to_s}") if levels.include?(obj_or_str.class)
      else
        @logger.info(obj_or_str)
      end
      obj_or_str
    end

    def sep()
      @logger.info('')
    end
  end

  def self.log_event(obj_or_str)
    $el.log_event(obj_or_str)
  end
end

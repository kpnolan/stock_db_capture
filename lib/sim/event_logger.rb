#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Sim
  class EventLogger < Subsystem

    attr_reader :levels, :logger

    def initialize(sm, cm)
      super(sm, cm, self.class)

      path = File.join(output_dir, (cval(:prefix) ? cval(:prefix)+'_' : cval(:position_table)+'_'))
      path << 'sim_events.log'
      File.truncate(path, 0) if File.exist?(path)
      @logger = ActiveSupport::BufferedLogger.new(path)
      @levels = case cval(:log_level)
                when 0 then []
                when 1 then [SimSummary]
                when 2 then [SimSummay, SimPosition]
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

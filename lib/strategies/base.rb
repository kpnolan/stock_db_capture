require 'rubygems'
require 'ruby-debug'
require 'strategies/closures'

module Strategies

  module Base
    def close_under_min(ta_props)
      time_array = []
      ta_props.each_pair do |meth, props|
        props.reverse_merge! :result => :first
        raise ArgumentError, "properties has must include :threshold}" unless props.has_key? :threshold
        values = send(meth, props)
        time_array << props[:time] = index2time(under_threshold(props[:threshold], values).first)
      end

      min_time = time_array.min do |a,b|
        case
        when a && b : a <=> b
        when a.nil? && b : 1
        when b.nil? && a : -1
        else 0
        end
      end
      ta_props.each_pair do |meth, props|
        return min_time, meth if props[:time] == min_time
      end
      [nil, nil]
    end

    def close_crossing_value(ta_props)
      time_array = []
      ta_props.each_pair do |meth, props|
        raise ArgumentError, "properties has must include :threshold}" unless props.has_key? :threshold
        values = send(meth, props)

        case props[:direction]
        when :under : time_array << props[:time] = index2time(under_threshold(props[:threshold], values).first)
        when :over : time_array << props[:time] = index2time(over_threshold(props[:threshold], values).first)
        else
          raise ArgumentError, ":direction must be :over or :under"
        end
      end

      min_time = time_array.min do |a,b|
        case
        when a && b : a <=> b
        when a.nil? && b : 1
        when b.nil? && a : -1
        else 0
        end
      end
      ta_props.each_pair do |meth, props|
        return min_time, meth, result_at(min_time, props[:result]) if props[:time] == min_time
      end
      debugger
    end
  end

  def closure_delta(conditions)
    conditions.each_pair do |meth, props|
      raise ArgumentError, "properties has must include :threshold parameter" unless props.has_key? :threshold
      last_val = send(meth, props.merge(:result => :last))
      delta = last_val - props[:threshold]
      conditions[meth].merge!(:delta => delta)
    end
  end
end


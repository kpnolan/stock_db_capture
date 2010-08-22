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
        when a && b then a <=> b
        when a.nil? && b then 1
        when b.nil? && a then -1
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
        when :under then time_array << props[:time] = index2time(under_threshold(props[:threshold], values).first)
        when :over then time_array << props[:time] = index2time(over_threshold(props[:threshold], values).first)
        else
          raise ArgumentError, ":direction must be :over or :under"
        end
      end

      min_time = time_array.min do |a,b|
        case
        when a && b then a <=> b
        when a.nil? && b then 1
        when b.nil? && a then -1
        else 0
        end
      end
      ta_props.each_pair do |meth, props|
        return min_time, meth, result_at(min_time, props[:result]) if props[:time] == min_time
      end
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


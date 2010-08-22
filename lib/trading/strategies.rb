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

module Trading
  module Strategies

    class StrategyException < Exception
      def initialize(msg)
        super
      end
    end

    def eval_crossing(indicator_config)
      # No deep copy in Ruby so Marshal is the only way to do it
      str = Marshal.dump(indicator_config)
      ta_props = Marshal.restore(str)
      indicators = ta_props.keys.map(&:to_s).sort.map(&:to_sym)

      indicators.each do |meth|
        ta_props[meth].reverse_merge! :result => :last
        raise ArgumentError, "properties has must include :threshold" unless ta_props[meth].has_key? :threshold
        value = ta_props[meth][:value] = send(meth, ta_props[meth])
        ta_props[meth][:delta] = case ta_props[meth][:direction]
                                 when :under then ta_props[meth][:threshold] - value
                                 when :over then value - ta_props[meth][:threshold]
                                 else
                                   raise ArgumentError, ":direction must be :over or :under"
                                 end
        ta_props[meth][:ratio] = (ta_props[meth][:threshold] - value) / (ta_props[meth][:range].end - ta_props[meth][:range].begin).abs
      end

      delta_ratios = indicators.map { |meth| ta_props[meth][:ratio] }
      delta_ratios.sort!
      indicators.each do |meth|
        ta_props[meth][:min] = true if ta_props[meth][:ratio] == delta_ratios.first
        ta_props[meth][:crossed] = true if ta_props[meth][:delta] <= 0.0
      end
      ta_props
    end
  end
end

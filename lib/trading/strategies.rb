# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

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

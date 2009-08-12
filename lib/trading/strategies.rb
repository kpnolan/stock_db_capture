module Trading
  module Strategies

    class StrategyException < Exception
      def initialize(msg)
        super(msg)
      end
    end

    def rsi_open(threshold, options={})
      options.reverse_merge! :plot_results => false, :result => :raw
      rsi_vec, dummy = rsi(options)
      rsi, last_sample = rsi_vec[-1], index2time(-1) #fixme non neg indexes
      raise StrategyException, "Timeseries last element not today: #{last_sample.to_s(:db)}" if last_sample != Date.today
      rsi >= threshold
    end

    def rsi_rvi_close(options)
      options.reverse_merge! :plot_results => false, :result => :raw
      rsi_threshold = options[:rsi_threshold]
      rvi_threshold = options[:rvi_threshold]
      rsi_vec, dummy = rsi(options)
      rvi_vec, dummy = rvi(options)

      rsi = rsi_vec[-1]
      rvi = rvi_vec[-1]
      last_sample = index2time(-1) #fixme nonneg index
      raise StrategyException, "Timeseries last element not today: #{last_sample.to_s(:db)}" if last_sample != Date.today

      rsi >= rsi_threshold || rvi >= rvi.threshold
    end
  end
end

module Statistics
  module Evaluator

    class JobException
      def initialize(msg)
        super(msg)
      end
    end

    class Job

      attr_reader :scan, :ticker, :date_range, :ts, :ticker_id, :options, :ticker_ids, :timeseries_opts
      attr_reader :family_name, :population, :options


      def initialze(family_name, population, options={ })
        @options = options.reverse_merge :timeseries => [ { :resolution => 1.day } ]
        @family_name = family_name
        @scan = Scan.find_by_name(population)
        @date_range = scan.start_date..scan.end_date
        @timeseries_opts = options[:timeseries].reverse_merge :populate => true
      end

      def run(logger)
        $logger = logger
        count = 0
        for tid in (@ticker_ids = scan.population_ids)
          begin
            @ticker = Ticker.find tid
            logger.info("Computing results for #{ticker.symbol} #{count} of #{@ticker_ids.length}")

            ts = Timeseries.new(ticker.symbol, date_range, params[:resolution], timeseries_opts)

            family = $indicator_families.find { |family| family.name == family_name}

            family.indicators do |ind|
              raise JobException, "invalid method: '#{ind.name}' of family: #{family.name}" unless ts.respond_to? ind.name
              rvecs = ts.send(ind.name, :time_period => ind.time_period, :plot_results => false, :results => :raw)
              raise JobException, "Results for :#{ind.name}(#{ind.time_period} is of the wrong form: #{rvecs.class}" unless rvecs.is_a? Array and rvecs.length > 0 and rvecs.first.is_a? GSL::Vector
              i = 0
              rvecs.first.each do |val|
                TaSeries.create!(:ticker_id => tid, :ta_spec_id => ind[:id], :stime => ts.index2time(i), :value => val)
                i += 1
              end
              ts.clear_results
            end
            count += 1
          rescue TimeseriesException => e
            logger.error("#{e.class.to_s}: '#{e.to_s}' skipping to next symbol")
            next
          end
        end
      end
    end
  end
end



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
module Statistics
  module Evaluator

    class TitsJobException
      def initialize(msg)
        super(msg)
      end
    end

    class Job

      attr_reader :scan, :ticker, :date_range, :ts, :ticker_id, :options, :ticker_ids, :timeseries_opts
      attr_reader :family_name, :population, :options

      def initialize(family_name, population, options={ })
        @options = options.reverse_merge :resolution => 1.day
        @family_name = family_name
        @scan = Scan.find_by_name(population)
        @date_range = scan.start_date..scan.end_date
        @timeseries_opts = self.options.merge :populate => true
      end

      def run(logger)
        $logger = logger
        count = 0
        for tid in (@ticker_ids = scan.population_ids)
          begin
            @ticker = Ticker.find tid
            logger.info("Computing results for #{ticker.symbol} #{count} of #{@ticker_ids.length}")

            ts = Timeseries.new(ticker.symbol, date_range, timeseries_opts[:resolution], timeseries_opts)

            result_ok = lambda { |result| result.is_a? Array and result.length > 0 and result.first.is_a? GSL::Vector }

            family = $indicator_families.find { |family| family.name == family_name}

            family.indicators.each do |ind|
              method = ind.indicator.name
              debugger
              raise TitsJobException, "invalid method: '#{method}' of family: #{family.name}" unless ts.respond_to? method
              rvecs = ts.send(method, :time_period => ind.time_period, :plot_results => false, :result => :raw)
              raise TitsJobException, "Results for :#{ind.name}(#{ind.time_period} is of the wrong form: #{rvecs.class}" unless result_ok.call(rvecs)
              i = 0
              rvecs.first.each do |val|
                TaSeries.create!(:ticker_id => tid, :ta_spec_id => ind.id, :stime => ts.index2time(i), :value => val)
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



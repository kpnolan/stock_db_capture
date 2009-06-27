# Module: Experiment
#
# Handles everything to do with experiments, from creating them, running them, to outputting
# of results compatible with input to R or any spreadsheet
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'statistics/base'

module Statistics
  module Experiment
    class Test
      attr_reader :study, :scan, :ticker, :date_range, :ts, :ticker_id, :block, :options, :ticker_ids, :timeseries, :ts_hash, :limit

      def initialize(study_name, options, &block)
        @options = options.reverse_merge :timeseries => [ { :resolution => 1.day } ]
        raise ArgumentError, "option must include a :with which defines what population this experiment is operating on" if options[:with].nil?
        @scan = Scan.find_by_name(options[:with])
        @study = $study if options[:version] == :memory
        @study = Scan.find_by_name_and_version(study_name.to_s, options[:version]) if options[:version].is_a? String
        raise ArgumentError, "Study: #{study_name} is undefined" if study.nil?
        raise ArgumentError, "Scan: #{options[:with]} is undefined" if scan.nil?
        @block = block
        study.import_dates(scan)
        @date_range = study.start_date..study.end_date
        @timeseries = options[:timeseries]
        @limit = options[:limit]
      end

      def run()
        if options[:bypass]
          instance_eval(&block)
          return
        end
        count = 0
        for tid in (@ticker_ids = scan.population_ids)
          begin
            @ticker = Ticker.find tid
            puts "Computing results for #{ticker.symbol}"
            @ts_hash = {}
            timeseries.each do |params|
              ts_hash[timeseries_params_key(params)] = Timeseries.new(ticker.symbol, date_range, params[:resolution], params)

            end
            for factor in study.factors.find(:all, :order => 'indicator_id, result')
              params = factor.params
              memo = ts_hash[timeseries_params_key(params)].send(factor.name, factor.params.merge(:noplot => true, :result => :memo))
              actual_result = factor.name == 'extract' ? 'value' : factor.result
              memo.each_from_result(actual_result) do |pair|
                value, date = pair
                begin
                  StudyResult.create!(:factor_id => factor.id, :ticker_id => ticker.id, :date => date, :value => value)
                rescue Exception => e
                  puts "Problem with #{factor.name}:#{factor.result}"
                end
              end
            end
          rescue TimeseriesException => e
            puts e.to_s
            next
          end
          count += 1
          break if limit && count == limit
        end
        instance_eval(&block)
      end
    end

    def timeseries_params_key(hash)
      "res:#{hash[:resolution]},stride:#{hash[:stride]},stride_offset:#{hash[:stride_offset]}"
    end

    def make_csv()
      sql = "select distinct(ticker_id) from study_results left outer join factors on factors.id = factor_id where study_id = #{study.id}"
      ticker_ids = Study.connection.select_values(sql).map { |sr| sr.to_i } if ticker_ids.nil?
      ticker_ids.each do |tid|
        symbol = Ticker.find(tid).symbol
        name = format_filename(study, symbol)
        begin
          @date_vec = nil
          table = gather_factor_data(study, tid)
          FasterCSV.open(name, "w") do |csv|
            csv << header_row(study)
            table.each do |row|
              csv << row
            end
          end
        rescue Exception => e
          puts "Array wasn't square, skipping #{File.basename(name)}"
        end
      end
    end

    def gather_factor_data(study, tid)
      columns = []
      study.factors.each do |factor|
        if @date_vec.nil?
          @date_vec = factor.study_results.find(:all, :conditions => { :ticker_id => tid}, :order => 'date' ).map { |sr| sr.date.to_s(:db) }
          columns << @date_vec
        end
        columns << factor.study_results.find(:all, :conditions => { :ticker_id => tid}, :order => 'date' ).map { |sr| sr.value }
      end
      columns.transpose
    end

    def format_filename(study, symbol)
      File.join(RAILS_ROOT, 'tmp', 'studies',
                "#{study.name}-#{study.version}.#{study.sub_version}.#{study.iteration}-#{symbol}.csv")
    end

    def header_row(study)
      ['date'].concat(study.factors.map { |f| f.to_s(:short) })
    end
  end
end

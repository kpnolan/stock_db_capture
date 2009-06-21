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
      attr_reader :study, :scan, :ticker, :date_range, :ts, :ticker_id, :block, :options

      def initialize(study_name, options, &block)
        @options = options.reverse_merge :resolution => 1.day
        raise ArgumentError, "option must include a :with which defines what population this experiment is operating on" if options[:with].nil?
        @scan = Scan.find_by_name(options[:with])
        @study = $study if options[:version] == :memory
        @study = Scan.find_by_name_and_version(study_name.to_s, options[:version]) if options[:version].is_a? String
        raise ArgumentError, "Study: #{study_name} is undefined" if study.nil?
        raise ArgumentError, "Scan: #{options[:with]} is undefined" if scan.nil?
        @block = block
        study.import_dates(scan)
        @date_range = study.start_date..study.end_date
      end

      def run()
        for tid in scan.population_ids
          @ticker = Ticker.find tid
          @ts = Timeseries.new(ticker.symbol, date_range, options[:resolution], options)
          for factor in study.factors
            puts "Performing #{factor.name}.."
            memo = ts.send(factor.name, factor.params.merge(:noplot => true, :result => :memo))
            memo.each do |pair|
              value, date = pair
              StudyResult.create!(:factor_id => factor.id, :ticker_id => ticker.id, :date => date, :value => value)
            end
          end
        end
        instance_eval(&block)
      end
    end

    def make_csv(symbol)
      symbol = symbol.to_s.upcase
      name = format_filename(study)
      @ticker_id = Ticker.find_by_symbol(symbol).id
      table = gather_factor_data(study)
      FasterCSV.open(name, "w") do |csv|
        csv << header_row(study)
        table.each do |row|
          csv << row
        end
      end
    end

    def gather_factor_data(study)
      columns = []
      study.factors.each do |factor|
        columns << factor.study_results.find(:all, :conditions => { :ticker_id => ticker_id }, :order => :date ).map { |sr| sr.value }
      end
      columns.transpose
    end

    def format_filename(study)
      "#{study.name}.#{study.version}.#{study.sub_version}-#{study.iteration}.csv"
    end

    def header_row(study)
      study.factors.map { |f| f.to_s(:short) }
    end
  end
end

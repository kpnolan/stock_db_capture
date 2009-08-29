# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'faster_csv'
require 'rbgsl'

module ExcelSimulationDumper

  include TradingCalendar

  OCHLV = [:date, :open, :high, :low, :close, :volume, :logr]

  attr_reader :logger

  #
  # Takes either the names or the actual ActiveRecord objects for which to construct a .csv file from the positions
  # with the characteristics of the args passed. Each arg default to nil which means it is a wildcard in the selection, e.g.
  # make_sheet() will select all positions while make_sheet(:rsi_open_14) will include a position with that entry strategy. Each non-nil
  # further constrains the match.
  #
  def make_sheet(entry_strategy=nil, exit_strategy=nil, scan=nil, options={})
    options.reverse_merge! :values => [:high, :low], :pre_days => 0, :post_days => 30, :keep => false, :log => 'make_sheet'
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', "#{options[:log]}.log")) if options[:log]

    args = validate_args(entry_strategy, exit_strategy, scan)
    conditions = build_conditions(args)

    csv_suffix = args.last.nil? ? options[:year] : args.last.name
    csv_suffix += '-' unless csv_suffix.nil?
    FasterCSV.open(File.join(RAILS_ROOT, 'tmp', "positions#{csv_suffix}.csv"), 'w') do |csv|
      csv << make_header_row(options)
      positions = Position.find(:all, :conditions => conditions)
      positions.each do |pos|
        symbol = pos.ticker.symbol
        entry_date =   pos.entry_date.to_date.to_s
        exit_date =    pos.exit_date.nil? ? '': pos.exit_date.to_date.to_s
        entry_price =  pos.entry_price
        exit_price =   pos.exit_price.nil? ? '': pos.exit_price
        days_held =    pos.days_held.nil? ? '' : pos.days_held
        row = []
        row << symbol
        row << entry_date
        row << exit_date
        row << entry_price
        row << exit_price
        row << days_held
        row << pos.stop_loss == 1 ? 'TRUE' : 'FALSE'
        range_start = trading_date_from(entry_date, -options[:pre_days])
        range_end = trading_date_from(pos.entry_date, options[:post_days])
        begin
          ts = Timeseries.new(symbol, range_start..range_end, 1.day, :populate => true, :pre_buffer => 0)
        rescue TimeseriesException => e
          logger.error("Position skipped #{e.to_s}")
          next
        end
        ts.set_enum_attrs(options[:values])
        logger.info("#{symbol}\t#{entry_date.to_s}\t#{ts.length}") if logger
        ts.each { |vec| vec.each { |e| row << e } }
        csv << row
        csv.flush
      end
    end
    true
  end

  def make_header_row(options)
    row = []
    vals = options[:values]
    idx = 0
    range = (0-options[:pre_days])..options[:post_days]
    row << 'symbol'
    row << 'entry-date'
    row << 'exit-date'
    row << 'entry-price'
    row << 'exit-price'
    row << 'days-held'
    row << 'stop-loss'
    range.to_a.each do |idx|
      vals.each { |v| row << "#{v.to_s}#{idx}" }
    end
    row
  end

  def validate_args(entry_strategy, exit_strategy, scan)
    arg_num = 1
    args = [:entry_strategy, :exit_strategy, :scan].map do |sym|
      name = sym.to_s
      arg = eval(name)
      model = name.classify.constantize
      obj = case arg
      when String, Symbol
        raise ArgumentError, "Argument ##{arg_num} (#{arg}) is not valid name in table '#{name.tableize}'" if (obj = model.find_by_name(arg.to_s)).nil?
        obj
      when ActiveRecord::Base
        raise ArgumentError, "Argument ##{arg_num} (#{name}) is an #{arg.class}, not a #{name.classify}" unless arg.is_a? model
        arg
      when NilClass
        nil
      else
        raise ArgumentError, "Argument ##{arg_num} (#{name}) must be a #{name.classify} or nil"
      end
      arg_num += 1
      obj
    end
    args
  end

  def build_conditions(args)
    non_nils = args.compact
    fkeys = non_nils.map { |ar| ar.class.to_s.foreign_key }.map(&:to_sym)
    pairs = fkeys.zip(non_nils.map { |ar| ar[:id] })
    pairs.inject({}) { |h, p| h[p.first] = p.last; h }
  end
end


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

require 'rbgsl'
require 'set'

module ExcelSimulationDumper

  extend TradingCalendar

  OCHLV = [:opening, :close, :high, :low, :volume]

  attr_reader :logger

  #
  # Takes either the names or the actual ActiveRecord objects for which to construct a .csv file from the positions
  # with the characteristics of the args passed. Each arg default to nil which means it is a wildcard in the selection, e.g.
  # make_sheet() will select all positions while make_sheet(:rsi_open_14) will include a position with that entry strategy. Each non-nil
  # further constrains the match.
  #
  def make_sheet(entry_trigger=nil, entry_strategy=nil, exit_trigger=nil, exit_strategy=nil, scan=nil, options={})
    options.reverse_merge! :values => OCHLV, :pre_days => 0, :post_days => 30, :keep => false, :log => 'make_sheet'
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', "#{options[:log]}.log")) if options[:log]

    #
    # TODO what happens if an indicator is supplied twice (or anything for that matter)
    #
    core_values = OCHLV.to_set
    options[:indicators] = (options[:values].to_set - core_values).to_a

    args = validate_args(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan)
    conditions = build_conditions(args)

    csv_suffix = args.last.nil? ? options[:year] : args.last.name
    csv_suffix = '-' + csv_suffix unless csv_suffix.nil?
    CSV.open(File.join(RAILS_ROOT, 'tmp', "positions#{csv_suffix}.csv"), 'w') do |csv|
      csv << make_header_row(options)
      positions = Position.find(:all, :conditions => conditions, :include => :ticker, :order => 'tickers.symbol, ettime')
      positions.each { |position| csv << field_row(position, options) unless position.entry_date.nil? }
      csv.flush
    end
    true
  end

  def field_row(position, options)
    returning [] do |row|
      symbol        = position.ticker.symbol
      etrigger_date  = position.ettime.to_formatted_s(:ymd)
      entry_date    = unless_nil(position.entry_date, :to_formatted_s, :ymd)
      xtrigger_date = position.xttime.to_formatted_s(:ymd)
      exit_date     = unless_nil(position.exit_date, :to_formatted_s, :ymd)
      etrigger_price = position.etprice
      entry_price   = unless_nil(position.entry_price, :to_s)
      xtrigger_price = unless_nil(position.xtprice, :to_s)
      exit_price    = unless_nil(position.exit_price, :to_s)
      days_held     = unless_nil(position.days_held, :to_s)
      closed        = position.closed ? 'TRUE' : 'FALSE'
      row << symbol
      row << etrigger_date
      row << entry_date
      row << xtrigger_date
      row << exit_date
      row << etrigger_price
      row << entry_price
      row << xtrigger_price
      row << exit_price
      row << days_held
      row << closed
      range_start = Timeseries.trading_date_from(position.ettime, -options[:pre_days])
      range_end = Timeseries.trading_date_from(position.ettime, options[:post_days])
      begin
        indicators = options[:indicators]
        populate = indicators.empty?
        ts = Timeseries.new(symbol, range_start..range_end, 1.day, :pre_buffer => 0, :populate => populate)
        @indicators_valid ||= indicators.all? { |method| ts.respond_to? method }
        report_unsupported_methods(ts, indicaors) unless @indicators_valid
        compute_indicators(ts, indicators)
        options[:values].each do |val|
          if indicators.include? val
            row.concat(ts.result_hash[val].to_a)
          else
            row.concat(ts.value_hash[val][ts.index_range])
          end
        end
      rescue TimeseriesException => e
        logger.error("Position skipped #{e.to_s}")
      end
    end
  end

  def unless_nil(var, method, *args)
    var.nil? ? '' : var.send(method, *args)
  end

  def make_header_row(options)
    row = []
    vals = options[:values]
    idx = 0
    range = (-options[:pre_days])..options[:post_days]
    row << 'symbol'
    row << 'trigger-date'
    row << 'entry-date'
    row << 'exit-trigger-date'
    row << 'exit-date'
    row << 'trigger-price'
    row << 'entry-price'
    row << 'exit-trigger-price'
    row << 'exit-price'
    row << 'days-held'
    row << 'closed'
    vals.each do |val|
      range.to_a.each do |idx|
        row << "#{val}#{idx}"
      end
    end
    row
  end

  def validate_args(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan)
    arg_num = 1
    args = [:entry_trigger, :entry_strategy, :exit_trigger, :exit_strategy, :scan].map do |sym|
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
    pairs = fkeys.zip(non_nils.map { |ar| ar.id })
    attrs = pairs.inject({}) { |h, p| h[p.first] = p.last; h }
  end

  def report_unsupported_methods(ts, methods)
    invalid_methods = methods.reject { |method| ts.respond_to? method }
    raise ArgumentError, "the following indicators are not supported #{invalid_methods.join(', ')}"
  end

  def compute_indicators(ts, indicators)
    indicators.each { |indicator| ts.send(indicator) }
    indicators
  end
end


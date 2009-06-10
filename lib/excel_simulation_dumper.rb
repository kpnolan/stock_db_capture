require 'rubygems'
require 'faster_csv'
require 'rbgsl'

module ExcelSimulationDumper

  include TradingCalendar

  OCHLV = [:date, :open, :high, :low, :close, :volume, :logr]

  def make_sheet(strategy=nil, options={})
    options.reverse_merge! :values => [:open, :close, :high, :low, :volume], :pre_days => 10, :post_days => 10, :keep => false
    day_count = options[:pre_days] + options[:post_days] + 1
    if strategy
      strategy_id = Strategy.find_by_name(strategy)
      conditions = { :strategy_id => strategy_id }
    else
      conditions = { }
    end
    FasterCSV.open(File.join(RAILS_ROOT, 'tmp', 'positions.csv'), 'w') do |csv|
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
        range_start = trading_days_from(entry_date, options[:pre_days], -1).last
        range_end = trading_days_from(pos.entry_date, options[:post_days]).last
        ts = Timeseries.new(symbol, range_start..range_end, 1.day, :pre_buffer => false)
        ts.set_enum_attrs(options[:values])
        if ts.length == day_count || options[:keep]
          puts "#{symbol}\t#{entry_date.to_s}\t#{ts.length}"
          ts.each { |vec| vec.each { |e| row << e } }
          csv << row
          csv.flush
        else
          debugger
          puts "#{symbol}\t#{entry_date.to_s}\t#{ts.length} <<<<<<<<<<<<<"
        end
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
    range.to_a.each do |idx|
      vals.each { |v| row << "#{v.to_s}#{idx}" }
    end
    row
  end
end


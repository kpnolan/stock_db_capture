require 'faster_csv'

module LoadIntradayBars

  attr_accessor :symbol, :minute, :target_table, :filename, :logger, :prev_close, :close_index, :count, :ticker_id

  CSV_COLUMS = [:date, :start, :open, :high, :low, :close, :volume]

  def initialize(filename, logger=nil)
    if filename =~ /^([A-Z]+)_([0-9]+).csv$/
      self.symbol, self.minute = $1, $2.to_i
    else
      raise ArgumentError, "filename #{filename} is not of the form SYMBOL_99.csv"
    end

    self.ticker_id = Ticker.find_by_symbol(symbol).id
    raise ArgumentError, "Cannot find Ticker for #{symbol}" if ticker_id.nil?

    self.filename = filename
    self.target_table = "bar_#{minute}s"
    self.logger = logger
    self.close_index = CSV_COLUMS.find_index :close
    self.prev_close = nil
    self.count = 0
  end

  def load_table()
    filename = File.join("#{RAILS_ROOT}", "db", "data", self.filename)
    Aggregate.set_table_name(self.target_table)
    Aggregate.benchmark("Loading #{minute} bars for #{symbol}") do
      FasterCSV.foreach(filename) do |row|
        load_row(row)
        self.count += 1
      end
    end
    self.logger.info("Loaded #{count} #{minute} minute bars for #{symbol}")
  end

  def load_row(row)
    r, logr, close = 0.0, 1.0, 0.0
    unless prev_close.nil?
      close = row[close_index].to_f
      r = (close/prev_close)
      logr = Math.log(r)
    end
    #
    # It is critical that the order of the csv columns match that of CSV_COLUMS
    #
    columns = row.dup
    ar = Aggregate.new do |ar|
      CSV_COLUMS.each {  |attr| ar[attr] = row.shift }
      ar.ticker_id = ticker_id
      ar.r = r
      ar.logr = logr
      ar.start = "#{ar.date} #{columns[1]}"
    end
    ar.save!
    self.prev_close = ar.close
  end
end


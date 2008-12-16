# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.
class LoadHistoricalQuotesWorker < BackgrounDRb::Rails

  def do_work(args)
    start_date = args[:start_date]
    end_date = args[:end_date]
    @t_ids = args[:ticker_ids]
    @length = @t_ids.length
    ActiveRecord::Base.silence do
      @t_ids.each do |@tid|
        t = Ticker.find_by_id @tid
        unless t.nil?
          rows = YahooFinance::get_historical_quotes(t.symbol, start_date, end_date, 'z')
          @logger.info("#{t.symbol} returned #{rows.length}")
          rows.each do |row|
            create_history_row(t.id, row)
          end
        end
      end
    end
  end

  def progress
    @t_ids.index(@tid).to_f/@length.to_f
  end

  private

  def create_history_row(ticker_id, row)
    attrs = [ :date, :open, :high, :low, :close, :volume, :adj_close]
    DailyClose.new do |ar|
      attrs.each {  |attr| ar[attr] = row.shift }
      ar.ticker_id = ticker_id
      ar.month = ar.date.month
      ar.week = ar.date.cweek
    end.save!
  end
end

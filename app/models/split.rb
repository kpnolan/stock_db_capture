# == Schema Information
# Schema version: 20091029212126
#
# Table name: splits
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)
#  date       :date
#  from       :integer(4)
#  to         :integer(4)
#  created_on :date
#

class Split < ActiveRecord::Base
  belongs_to :ticker

  extend BarUtils

  class << self
    def load(logger)
      ticker_ids = Ticker.find(:all, :conditions => "symbol not like '%-%'").map(&:id)
      chunk = BarUtils::Splitter.new(ticker_ids)
      count = 0
      for ticker_id in chunk do
        ticker = Ticker.find ticker_id
        symbol = ticker.symbol
        cnt = load_from_ticker_id(ticker_id, :logger => logger)
        count += 1
        logger.info "(#{chunk.id}) loaded #{cnt} splits for #{symbol}\t#{count} of #{chunk.length}"
      end
    end

    def load_from_ticker_id(ticker_id, options={})
      symbol = Ticker.find(ticker_id).symbol
      sp = YahooFinance::SplitParser.new(symbol, options)
      split_vec = sp.splits()
      count = 0
      split_vec.each do |split|
        begin
          next unless find(:first, :conditions => { :ticker_id => ticker_id, :date => split[:date] }).nil?
          create! split.merge!(:ticker_id => ticker_id, :created_on => Date.today)
        rescue Exception => e
          logger.error("#{e.class}: #{e.to_s}")
          retry
        end
        count += 1
      end
      count
    end
  end
end

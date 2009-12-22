# == Schema Information
# Schema version: 20091220213712
#
# Table name: rsi_target_studies
#
#  id                   :integer(4)      not null, primary key
#  ticker_id            :integer(4)
#  start_date           :date
#  end_date             :date
#  time_period          :integer(4)
#  slope                :float
#  chisq                :float
#  rsi                  :float
#  prior_price          :float
#  last_price           :float
#  pos_delta            :float
#  neg_delta            :float
#  pos_delta_plus       :float
#  neg_delta_plus       :float
#  pos_delta_plus_ratio :float
#  neg_delta_plus_ratio :float
#

require 'ostruct'

class RsiTargetStudy < ActiveRecord::Base
  belongs_to :ticker

  extend TradingCalendar
  extend BarUtils

  class << self
    def generate(logger)
      ticker_ids = tickers_with_some_history()
      max = ticker_ids.length
      start_date = end_date = self.trading_date_from(Date.today, -1)
      exp_date = self.trading_date_from(start_date, -1)
      chunk = Splitter.new(ticker_ids)
      count = 0
      for ticker_id in chunk do
        ticker = Ticker.find(ticker_id)
        symbol = ticker.symbol
        next if symbol.nil?
        begin
          logger.info "(#{chunk.id}) loading #{symbol}\t#{count} of #{chunk.length}"
          ts1 = Timeseries.new(symbol, start_date..end_date, 1.day)
          ts2 = Timeseries.new(symbol, exp_date..exp_date, 1.day)
          target_rsi = ts1.rsi(:result => :last)
          prior_rsi = ts2.rsi(:result => :last)
          target_price = ts1.close[-1]
          last_price = prior_price = ts1.close[-2]
          slope, chisq = ts1.lrclose()
          pos_delta, neg_delta = ts2.invrsi_exp(:rsi => target_rsi)
          os = OpenStruct.new({ :start_date => start_date, :end_date => end_date,
                                :target_rsi => target_rsi, :prior_rsi => prior_rsi, :delta_rsi => target_rsi - prior_rsi,
                                :last_price => target_price, :slope => slope, :chisq => chisq,
                                :time_period => 14, :ticker_id => ticker_id, :pos_delta => pos_delta, :neg_delta => neg_delta})

          target_prices = {
            :pos_delta_plus =>     last_price+pos_delta,
            :neg_delta_plus =>     last_price+neg_delta,
          }

          target_prices.each_pair do |k,v|
            os.new_ostruct_member(k)
            os.send("#{k}=",v)
          end

          ratios = { }
          target_prices.each_pair do |k,v|
            r = (last_price - v)/last_price
            os.new_ostruct_member("#{k}_ratio")
            os.send("#{k}_ratio=",r)
          end

          attrs = os.marshal_dump
          attrs.each_pair { |k,v| attrs[k] = nil if (v.is_a?(Float) && (v.nan? || v.infinite? == 1 || v.infinite? == -1)) }
          create!(attrs)

        rescue TimeseriesException => e
          logger.error(e.to_s)
        end
        count += 1
      end
    end
  end
end

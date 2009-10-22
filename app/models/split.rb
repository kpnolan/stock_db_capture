# == Schema Information
# Schema version: 20091016185148
#
# Table name: splits
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  date      :date
#  from      :integer(4)
#  to        :integer(4)
#

class Split < ActiveRecord::Base
  belongs_to :ticker

  class << self
    def load_from_symbol(symbol, options={})
      ticker_id = Ticker.lookup(symbol).id
      sp = YahooFinance::SplitParser.new(symbol, options)
      split_vec = sp.splits()
      count = 0
      split_vec.each do |split|
        next unless find(:first, :conditions => { :ticker_id => ticker_id, :date => split[:date] }).nil?
        create! split.merge!(:ticker_id => ticker_id)
        count += 1
      end
      count
    end
  end
end

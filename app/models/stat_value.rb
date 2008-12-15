# == Schema Information
# Schema version: 20080813192644
#
# Table name: stat_values
#
#  id                      :integer(4)      not null, primary key
#  historical_attribute_id :integer(4)
#  ticker_id               :integer(4)
#  start_date              :date
#  end_date                :date
#  sample_count            :integer(4)
#  mean                    :float
#  min                     :float
#  max                     :float
#  stddev                  :float
#  absdev                  :float
#  skew                    :float
#  kurtosis                :float
#  slope                   :float
#  yinter                  :float
#  cov00                   :float
#  cov01                   :float
#  cov11                   :float
#  chisq                   :float
#  created_at              :datetime
#  updated_at              :datetime
#

class StatValue < ActiveRecord::Base

  belongs_to :ticker

  def self.create_row(attr, ticker, start_date, end_date, attr_hash)
    attr_hash.merge!(:ticker_id => ticker.id,
                     :historical_attribute_id => HistoricalAttribute.find_by_name(attr),
                     :start_date => start_date,
                     :end_date => end_date)
    create(attr_hash)
  end
end

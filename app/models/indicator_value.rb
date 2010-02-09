# == Schema Information
# Schema version: 20100205165537
#
# Table name: indicator_values
#
#  id            :integer(4)      not null, primary key
#  indicator_id  :integer(4)
#  itime         :datetime
#  value         :float
#  ticker_id     :integer(4)
#  entry_date    :datetime
#  valuable_id   :integer(4)
#  valuable_type :string(64)
#

class IndicatorValue < ActiveRecord::Base
  belongs_to :position, :foreign_key => [:ticker_id, :entry_date]
  belongs_to :valuable, :polymorphic => true

  class << self
    def record_element(etrigger, indicator_id, position, time, value)
      etrigger.indicator_values.create!(:indicator_id => indicator_id, :ticker_id => position.ticker_id,
                                       :entry_date => position.entry_date, :itime => time, :value => value)
    end
  end
end

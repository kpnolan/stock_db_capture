# == Schema Information
# Schema version: 20090906181342
#
# Table name: ta_specs
#
#  id           :integer(4)      not null, primary key
#  indicator_id :integer(4)
#  time_period  :integer(4)
#

class TaSpec < ActiveRecord::Base
  belongs_to :indicator

  validates_uniqueness_of :time_period, :scope => :indicator_id
  validates_numericality_of :time_period, :greater_than => 1

  class << self
    def create_spec(indicator, time_period)
      ind = indicator.to_s.downcase
      i = Indicator.create!(:name => ind) unless (i = Indicator.find_by_name(ind))
      is = create!(:indicator_id => i.id, :time_period => time_period) unless (is = find_by_indicator_id_and_time_period(i.id, time_period))
      is
    end
    def find_by_indicator_and_time_period(indicator, time_period)
      find_by_sql "SELECT ta.* FROM ta_specs ta, indicator i WHERE ta.indicator_id = i.id AND i.name = '#{indicator}' AND i.time_period = #{time_period}"
    end
  end
end

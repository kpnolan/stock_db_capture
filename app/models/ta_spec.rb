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
# == Schema Information
# Schema version: 20100205165537
#
# Table name: ta_specs
#
#  id           :integer(4)      not null, primary key
#  indicator_id :integer(4)
#  time_period  :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

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

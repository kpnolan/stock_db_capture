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
# Table name: ta_series
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)
#  ta_spec_id :integer(4)
#  stime      :datetime
#  value      :float
#  seq        :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class TaSeries < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :ta_spec

  include GSL

  class << self
    def predict(ticker_id, indicator, date=Date.today, seq=480, params = { })
      params.reverse_merge! :time_period => 14
      ta = TaSpec.find_by_name_and_time_period(indicator, params[:time_period])
      series = find(:all, :conditions => ["ticker_id = ? and date(stime) = ?", ticker_id, date], :order => "stime, seq").map { |ts| [ts.seq, ts.value] }
      seq_vec = series.map(&:first).to_gv
      val_vec = series.map(&:last).to_gv
      inter, slope, cov00, cov01, cov11, chisq, status = GSL::Fit.linear(seq_vec, val_vec)
      raise Exception, "Non-zero status for GSL::Fit.linear" unless status.zero?
      GSL::Fit::linear_est(seq, inter, slope, cov00, cov01, cov11)
    end
  end
end

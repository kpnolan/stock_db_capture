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
# Table name: current_listings
#
#  id                                      :integer(4)      not null, primary key
#  moving_ave_50_days_change_percent_from  :float
#  weeks52_change_from_low                 :float
#  weeks52_change_percent_from_low         :float
#  weeks52_range_low                       :float
#  weeks52_range_high                      :float
#  peg_ratio                               :float
#  dividend_yield                          :float
#  price_per_eps_estimate_current_year     :float
#  oneyear_target_price                    :float
#  dividend_per_share                      :float
#  short_ratio                             :float
#  price_persales                          :float
#  price_per_eps_estimate_next_year        :float
#  eps                                     :float
#  moving_ave_50_days                      :float
#  price_perbook                           :float
#  ex_dividend_date                        :date
#  moving_ave_200_days                     :float
#  book_value                              :float
#  eps_estimate_current_year               :float
#  market_cap                              :float
#  pe_ratio                                :float
#  moving_ave_200_days_change_from         :float
#  eps_estimate_next_year                  :float
#  ticker_id                               :integer(4)
#  moving_ave_200_days_change_percent_from :float
#  eps_estimate_next_quarter               :float
#  dividend_paydate                        :date
#  weeks52_change_from_high                :float
#  moving_ave_50_days_change_from          :float
#  ebitda                                  :float
#  weeks52_change_percent_from_high        :float
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class CurrentListing < ActiveRecord::Base
  belongs_to :ticker

  def symbol=(name)
  end

  def name
    ticker.name
  end
end

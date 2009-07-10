# == Schema Information
# Schema version: 20090707232154
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
end

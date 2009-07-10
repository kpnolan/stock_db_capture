# == Schema Information
# Schema version: 20090707232154
#
# Table name: scans_tickers
#
#  ticker_id :integer(4)
#  scan_id   :integer(4)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class ScansTickers < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :scan
end

# == Schema Information
# Schema version: 20090425175412
#
# Table name: scans_tickers
#
#  ticker_id :integer(4)
#  scan_id   :integer(4)
#

class ScansTickers < ActiveRecord::Base
  belongs_to :ticker
  belongs_to :scan
end
# == Schema Information
# Schema version: 20090528012055
#
# Table name: memberships
#
#  id                  :integer(4)      default(0), not null, primary key
#  ticker_id           :integer(4)
#  listing_category_id :integer(4)
#

class Membership < ActiveRecord::Base
end

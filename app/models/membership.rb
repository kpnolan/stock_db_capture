# == Schema Information
# Schema version: 20080813192644
#
# Table name: memberships
#
#  id                  :integer(4)      not null, primary key
#  ticker_id           :integer(4)
#  listing_category_id :integer(4)
#

class Membership < ActiveRecord::Base
end

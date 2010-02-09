# == Schema Information
# Schema version: 20100205165537
#
# Table name: memberships
#
#  id                  :integer(4)      default(0), not null, primary key
#  ticker_id           :integer(4)
#  listing_category_id :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Membership < ActiveRecord::Base
end

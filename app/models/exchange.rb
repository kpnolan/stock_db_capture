# == Schema Information
# Schema version: 20090729181214
#
# Table name: exchanges
#
#  id       :integer(4)      not null, primary key
#  symbol   :string(255)
#  name     :string(255)
#  country  :string(255)
#  currency :string(255)
#  timezone :string(255)
#

class Exchange < ActiveRecord::Base
end

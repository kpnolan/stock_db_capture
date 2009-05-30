# == Schema Information
# Schema version: 20090528233608
#
# Table name: sectors
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Sector < ActiveRecord::Base
end

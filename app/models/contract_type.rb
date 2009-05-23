# == Schema Information
# Schema version: 20090522155818
#
# Table name: contract_types
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class ContractType < ActiveRecord::Base
end

# == Schema Information
# Schema version: 20090707232154
#
# Table name: contract_types
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class ContractType < ActiveRecord::Base
end

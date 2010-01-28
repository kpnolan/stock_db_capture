# == Schema Information
# Schema version: 20100123024049
#
# Table name: study_results
#
#  id        :integer(4)      not null, primary key
#  factor_id :integer(4)
#  date      :date
#  value     :float
#  ticker_id :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class StudyResult < ActiveRecord::Base
  belongs_to :factor
  belongs_to :ticker
end

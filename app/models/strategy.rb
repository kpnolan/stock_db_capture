# == Schema Information
# Schema version: 20090425175412
#
# Table name: strategies
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  description :string(255)
#  params_yaml :string(255)
#

require 'yaml'

class Strategy < ActiveRecord::Base
  validates_presence_of :name, :params_yaml
  validates_uniqueness_of :name, :scope => :params_yaml

  attr_accessor :block

  class << self

    def record!(name, description, params_str)
      create!(:name => name.to_s.downcase, :description => description, :params_yaml => params_str)
    end

    def find_by_name(keyword_or_string)
      first(:conditions => { :name => keyword_or_string.to_s.downcase })
    end
  end
end


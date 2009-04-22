# == Schema Information
# Schema version: 20090403161440
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

  def Strategy.record(name, description, params)
    create!(:name => name.to_s.lowercase, :description => description, :params_yaml => params.to_yaml)
  end

end


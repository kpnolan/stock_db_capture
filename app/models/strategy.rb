# == Schema Information
# Schema version: 20090707232154
#
# Table name: strategies
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  open_description  :string(255)
#  open_params_yaml  :string(255)
#  close_params_yaml :string(255)
#  close_description :string(255)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'yaml'

class Strategy < ActiveRecord::Base

  has_and_belongs_to_many :positions
  has_and_belongs_to_many :scans

  validates_presence_of :name
  validates_uniqueness_of :name

  before_save :clear_associations_if_dirty

  def clear_associations_if_dirty
    scans.clear if changed?
    positions.clear if changed?
  end

  # Convert the yaml formatted hash of params back into a hash
  def open_params()
    @open_params ||= YAML.load(open_params_yaml)
  end

  def close_params()
    @close_params ||= YAML.load(close_params_yaml)
  end

  class << self

    def record_open!(name, description, params_str)
      if (s = Strategy.find_by_name(name))
        s.update_attributes!(:open_description => description, :open_params_yaml => params_str)
      else
        create!(:name => name.to_s.downcase, :open_description => description, :open_params_yaml => params_str)
      end
    end

    def record_close!(name, description, params_str)
      if (s = Strategy.find_by_name(name))
        s.update_attributes!(:close_description => description, :close_params_yaml => params_str)
      else
        create!(:name => name.to_s.downcase, :close_description => description, :close_params_yaml => params_str)
      end
    end

    def find_by_name(keyword_or_string)
      first(:conditions => { :name => keyword_or_string.to_s.downcase })
    end
  end
end


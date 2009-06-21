# == Schema Information
# Schema version: 20090618213332
#
# Table name: factors
#
#  id           :integer(4)      not null, primary key
#  study_id     :integer(4)
#  indicator_id :integer(4)
#  params_str   :string(255)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Hash
  # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
  #
  # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|   # <-- here's my addition (the 'sort')
          map.add( k, v )
        end
      end
    end
  end
end

class Factor < ActiveRecord::Base
  belongs_to :study
  belongs_to :indicator
  has_many :study_results, :dependent => :delete_all

  validates_presence_of :indicator_id, :params_str

  def name()
    indicator.name
  end

  def to_s(format)
    case format
    when :short : indicator.name
    when :long : "#{indicator.name}_#{format_params}"
    end
  end

  def params
    params = YAML.load(params_str)
  end

  class << self

    def create_from_args(study, fcn, params={})
      name = fcn.to_s.downcase
      params_str = params.to_yaml
      indicator = Indicator.find_by_name(name)
      indicator = Indicator.create!(:name => name) if indicator.nil?
      factor = study.factors.find(:first, :conditions => { :indicator_id => indicator.id, :params_str => params_str })
      factor = study.factors.create!(:indicator_id => indicator.id, :params_str => params_str) if factor.nil?
    end

    def find_by_name_and_params(study, name, params)
      study.factors.find(:first, :conditions => { :name => name, :parmas_str => params.to_yaml })
    end

    def format_params
      params_ary = YAML.load(params_str).sort { |a,b| "#{a.first}:#{a.last}" <=> "#{b.first}:#{b.last}" }.join('_')
    end
  end
end

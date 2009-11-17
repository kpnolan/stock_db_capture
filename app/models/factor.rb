# == Schema Information
# Schema version: 20091029212126
#
# Table name: factors
#
#  id           :integer(4)      not null, primary key
#  study_id     :integer(4)
#  indicator_id :integer(4)
#  params_str   :string(255)
#  result       :string(255)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Factor < ActiveRecord::Base

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

  belongs_to :study
  belongs_to :indicator
  has_many :study_results, :dependent => :delete_all

  validates_presence_of :indicator_id, :params_str

  def name()
    indicator && indicator.name
  end

  def to_s(format)
    results = TALIB_META_INFO_DICTIONARY[indicator.name.to_sym].stripped_output_names.map { |n| n.downcase }
    header = case
             when format == :short && result == results.first : result
             when format == :short && result != results.first : result
             when :long : "#{indicator.name}.#{result}"
             end
    debugger if header.nil? or header == ''
    header
  end

  def params
    params = YAML.load(params_str)
  end

  class << self

    def create_from_args(study, fcn, params={})
      params.reverse_merge! :resolution => 1.day
      results = TALIB_META_INFO_DICTIONARY[fcn].stripped_output_names.map { |n| n.downcase }
      if params[:result]
        selected = params[:result].is_a?(Array) ? params[:result] : [ params[:result] ]
        selected.delete_if { |name| !results.include? name.to_s }
      elsif fcn == :extract
        selected = params[:slot].is_a?(Array) ? params[:slot] : [ params[:slot] ]
      else
        selected = [ results.first ]
      end
      params.delete :result
      name = fcn.to_s
      indicator = Indicator.find_by_name(name)
      indicator = Indicator.create!(:name => name) if indicator.nil?
      selected.each do |result|
        params[:slot] = result if params.has_key? :slot
        params_str = params.to_yaml
        factor = study.factors.find(:first, :conditions => { :indicator_id => indicator.id, :params_str => params_str, :result => result.to_s })
        factor = study.factors.create!(:indicator_id => indicator.id, :params_str => params_str, :result => result.to_s ) if factor.nil?
      end
    end

    def find_by_name_and_params(study, name, params, result)
      study.factors.find(:first, :conditions => { :name => name, :parmas_str => params.to_yaml, :result => result })
    end

    def format_params
      params_ary = YAML.load(params_str).sort { |a,b| "#{a.first}:#{a.last}" <=> "#{b.first}:#{b.last}" }.join('_')
    end
  end
end

# == Schema Information
# Schema version: 20090621183035
#
# Table name: factors
#
#  id           :integer(4)      not null, primary key
#  study_id     :integer(4)
#  indicator_id :integer(4)
#  params_str   :string(255)
#  result       :string(255)
#

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
    results = TALIB_META_INFO_DICTIONARY[indicator.name.to_sym].stripped_output_names.map { |n| n.downcase }
    header = case
             when format == :short && result == results.first : indicator.name
             when format == :short && indicator.name == 'barval' : format_identity
             when format == :short && result != results.first : "#{indicator.name}-#{result}"
             when :long : "#{indicator.name}-#{result}_#{format_params}"
             end
    debugger if header.nil? or header == ''
    header
  end

  def params
    params = YAML.load(params_str)
  end

  def format_barval
    case
    when params.empty?  : 'close'
    when params[:slot]  : params[:slot]
    end
  end

  class << self

    def create_from_args(study, fcn, params={})
      results = TALIB_META_INFO_DICTIONARY[fcn].stripped_output_names.map { |n| n.downcase }
      if params[:result]
        selected = params[:result].is_a?(Array) ? params[:result] : [ params[:result] ]
        selected.delete_if { |name| !results.include? name.to_s }
      else
        selected = [ results.first ]
      end
      params.delete :result
      params_str = params.to_yaml
      name = fcn.to_s
      indicator = Indicator.find_by_name(name)
      indicator = Indicator.create!(:name => name) if indicator.nil?
      selected.each do |result|
        factor = study.factors.find(:first, :conditions => { :indicator_id => indicator.id, :params_str => params_str, :result => result.to_s })
        factor = study.factors.create!(:indicator_id => indicator.id, :params_str => params_str, :result => result.to_s ) if factor.nil?
      end
    end

    def find_by_name_and_params(study, name, params)
      study.factors.find(:first, :conditions => { :name => name, :parmas_str => params.to_yaml })
    end

    def format_params
      params_ary = YAML.load(params_str).sort { |a,b| "#{a.first}:#{a.last}" <=> "#{b.first}:#{b.last}" }.join('_')
    end
  end
end

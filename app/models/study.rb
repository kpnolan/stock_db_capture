# == Schema Information
# Schema version: 20100205165537
#
# Table name: studies
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  start_date  :date
#  end_date    :date
#  description :string(128)
#  version     :integer(4)
#  sub_version :integer(4)
#  iteration   :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Study < ActiveRecord::Base
  has_many :factors, :dependent => :delete_all
  has_many :study_results, :through => :factors, :dependent => :delete_all

  validates_presence_of :name#, :version, :sub_version, :iteration

  def import_dates(scan)
    if start_date && end_date && (start_date != scan.start_date || end_date != scan.end_date)
      raise ArgumentError, "You must roll a new version of the study as the times have changed"
    elsif start_date.nil? && end_date.nil?
      update_attributes!(:start_date => scan.start_date, :end_date => scan.end_date)
    end
  end

  class << self

    def create_with_version(name, options={ })
      name = name.to_s
      options.reverse_merge! :description => '', :increment => :none
      studies = find_all_by_name(name, :order => 'version, sub_version, iteration')
      study = studies.last
      case
      when options[:increment] == :redo then
        raise ArgumentError, ":redo given with no prior Study" unless study
        study.factors.destroy_all;
        study.update_attributes!(:start_date => nil, :end_date => nil)
        study
      when options[:increment] == :retain
        study
      when options[:increment] == :init then
        raise ArgumentError, ":increment => :init given when Study already exists, use :redo or :version" if study
        options[:version] = 1
        options[:sub_version] = 0
        options[:iteration] = 0
        create!(build_attrs(name, options))
      when options[:increment] == :iteration
        options[:version] = study.version
        options[:sub_version] = study.sub_version
        options[:iteration] = study.iteration + 1
        create!(build_attrs(name, options))
      when options[:increment] == :sub_version
        options[:version] = study.version
        options[:sub_version] = study.sub_version + 1
        options[:iteration] = 0
        create!(build_attrs(name, options))
      when options[:increment] == :version
        options[:version] = study.version + 1
        options[:sub_version] = 0
        options[:iteration] = 0
        create!(build_attrs(name, options))
      end
    end

    def find_by_name_and_version(name, version)
      raise ArgumentError, "Invalid version string ${version}" if version =~ /(\d+)\.(\d+)\.(\d+)/
      cond = { :name => name, :version => $1.to_i, :sub_version => $2.to_i, :iteration => $3.to_i }
      find(:first, :conditions => cond)
    end

    def build_attrs(name, options)
      attrs = options.merge :name => name.to_s
      attrs.delete_if { |k,v| !valid_attrs.member? k }
    end

    def valid_attrs()
      @@vattrs ||= Study.content_columns.map { |c| c.name.to_sym }
    end
  end
end

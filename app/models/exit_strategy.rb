# == Schema Information
# Schema version: 20091029212126
#
# Table name: exit_strategies
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  params      :string(255)
#  description :string(255)
#

class ExitStrategy < ActiveRecord::Base

  has_many :positions, :dependent => :nullify
  has_many :btest_positions, :dependent => :nullify

  validates_presence_of :name
  validates_uniqueness_of :name

  before_save :clear_associations_if_dirty

  def clear_associations_if_dirty
    positions.clear if changed?
  end

  # Convert the yaml formatted hash of params back into a hash
  def params()
    @params ||= YAML.load(self[:params])
  end

  class << self

    def create_or_update!(name, description, params_str)
      if (s = find_by_name(name))
        s.update_attributes!(:description => description, :params => params_str)
      else
        create!(:name => name.to_s.downcase, :description => description, :params => params_str)
      end
    end

    def find_by_name(keyword_or_string)
      first(:conditions => { :name => keyword_or_string.to_s.downcase })
    end
  end
end

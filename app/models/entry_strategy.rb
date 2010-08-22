#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
# == Schema Information
# Schema version: 20100205165537
#
# Table name: entry_strategies
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  params      :string(255)
#  description :string(255)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'yaml'

class EntryStrategy < ActiveRecord::Base

  has_many :positions, :dependent => :nullify, :autosave => true
  has_many :indicator_values, :as => :valuable

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


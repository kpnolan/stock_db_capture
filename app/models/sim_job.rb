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
# Table name: sim_jobs
#
#  id               :integer(4)      not null, primary key
#  user             :string(255)
#  dir              :string(255)
#  prefix           :string(255)
#  position_table   :string(255)
#  start_date       :date
#  end_date         :date
#  output           :string(255)
#  filter_predicate :string(255)
#  sort_by          :string(255)
#  initial_balance  :float
#  order_amount     :float
#  minimum_balance  :float
#  portfolio_size   :integer(4)
#  reinvest_percent :float
#  order_charge     :float
#  entry_slippage   :string(255)
#  exit_slippage    :string(255)
#  log_level        :integer(4)
#  keep_tables      :boolean(1)
#  job_started_at   :datetime
#  job_finished_at  :datetime
#

class SimJob < ActiveRecord::Base

  validates_presence_of :user, :position_table, :initial_balance, :order_amount, :minimum_balance, :order_charge
  validates_presence_of :entry_slippage, :exit_slippage, :log_level
  validates_numericality_of  :initial_balance, :order_amount, :minimum_balance, :order_charge, :log_level
  validate :portfolio_size_or_reinvest_percent
  validate :validate_output_directory

  before_save do
    self.job_started_at = nil
    self.job_finished_at = nil
  end

  def portfolio_size_or_reinvest_percent
     unless portfolio_size.blank? ^ reinvest_percent.blank?
       errors.add(:portfolio_size, "Reinvest Percent is also given; one one or the other is permitted")
    end
  end

  def validate_output_directory
    return if dir.blank?
    unless File.exist?(dir) and (fs = File::Stat.new(dir)) and fs.directory? and fs.writable?
      errors.add(:dir, "output directory: '#{dir}' doesn't exist or isn't a directory or isn't writable")
    end
  end

  def to_openstruct
    OpenStruct.new(SimJob.content_columns.inject({}) { |h, c| h[c.name.to_sym] = self[c.name]; h})
  end
end

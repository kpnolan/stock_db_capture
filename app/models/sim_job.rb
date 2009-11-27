class SimJob < ActiveRecord::Base

  validates_presence_of :user, :position_table, :initial_balance, :order_amount, :minimum_balance, :order_charge
  validates_presence_of :entry_slippage, :exit_slippage, :log_level
  validates_numericality_of  :initial_balance, :order_amount, :minimum_balance, :order_charge, :log_level
  validate :portfolio_size_or_reinvest_percent
  validate :validate_output_directory

  def portfolio_size_or_reinvest_percent
     unless portfolio_size.blank? ^ reinvest_percent.blank?
       errors.add(:portfolio_size, "Reinvest Percent is also given; one one or the other is permitted")
       errors.add(:reinvest_percent, "See above")
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

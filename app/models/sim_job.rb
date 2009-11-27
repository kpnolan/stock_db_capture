class SimJob < ActiveRecord::Base
  validates_presence_of :user, :position_table, :initial_balance, :order_amount, :minimum_balance, :order_charge
  validates_presence_of :entry_slippage, :exit_slippage, :log_level, :keep_tables
  validates_numericality_of  :initial_balance, :order_amount, :minimum_balance, :order_charge, :log_level
  validate :portfolio_size_or_reinvest_percent

  def portfolio_size_or_reinvest_percent
     unless portfolio_size.blank? ^ reinvest_percent.blank?
       errors.add(:portfolio_size, "Portfolio Size and Reinvest Percent cannot both be given")
       errors.add(:reinvest_percent, "Portfolio Size and Reinvest Percent cannot both be given")
    end
  end

  def to_openstruct
    OpenStruct.new(SimJob.content_columns.inject({}) { |h, c| h[c.name.to_sym] = self[c.name]; h})
  end
end

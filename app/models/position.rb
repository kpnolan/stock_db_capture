# == Schema Information
# Schema version: 20090311210559
#
# Table name: positions
#
#  id               :integer(4)      not null, primary key
#  portfolio_id     :integer(4)
#  ticker_id        :integer(4)
#  open             :boolean(1)
#  entry_date       :datetime
#  exit_date        :datetime
#  entry_price      :float
#  exit_price       :float
#  num_shares       :integer(4)
#  contract_type_id :integer(4)
#  side             :integer(4)
#  stop_loss        :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class Position < ActiveRecord::Base
  belongs_to :portfolio
  belongs_to :ticker

  def current_value

  end
end

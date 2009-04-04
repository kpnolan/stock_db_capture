class RestructurePositions < ActiveRecord::Migration
  def self.up
    remove_column :positions, :created_at
    remove_column :positions, :updated_at
    remove_column :positions, :contract_type_id
    remove_column :positions, :side

    add_column :positions, :strategy_id, :integer
    add_column :positions, :days_held, :integer
    add_column :positions, :nomalized_return, :float
    add_column :positions, :risk_factor, :float

  end

  def self.down
  end
end

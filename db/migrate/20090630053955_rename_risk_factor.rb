class RenameRiskFactor < ActiveRecord::Migration
  def self.up
    remove_column :positions, :risk_factor
    add_column :positions, :entry_pass, :integer
  end

  def self.down
    remove_column :positions, :entry_pass
    add_column :positions, :risk_factor, :float
  end
end
